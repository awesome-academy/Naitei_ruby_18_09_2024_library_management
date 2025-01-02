require "rails_helper"

RSpec.describe "RequestsController", type: :request do
  let(:user)          {create(:user)}
  let(:admin)         {create(:user, email: "admin@gmail.com", phone: "1112223334", is_admin: true)}
  let(:book)          {create(:book, author: create(:author), publisher: create(:publisher), genre: create(:genre))}
  let(:user_request)  {create(:request, borrower: user)}
  let(:admin_request) {create(:request, borrower: admin, status: :borrowing)}

  describe "GET /requests" do
    context "when user is not logged in" do
      before {get requests_path}

      include_examples "guest user redirection"
    end

    context "when user is logged in" do
      before {sign_in user}

      it "shows only user's requests" do
        user_request
        admin_request

        get requests_path

        expect(response.body).to include(user_request.status)
        expect(response.body).not_to include(admin_request.status)
      end
    end
  end

  describe "GET/requests/all" do
    context "when user is not logged in" do
      before {get requests_path}

      include_examples "guest user redirection"
    end

    context "when user is logged in" do
      before {sign_in user}

      it "shows only user's requests" do
        user_request
        admin_request

        get requests_path

        expect(response.body).to include(user_request.status)
        expect(response.body).not_to include(admin_request.status)
      end
    end

    context "when admin is logged in" do
      before {sign_in admin}

      it "shows all requests" do
        user_request
        admin_request

        get "/requests/all"

        expect(response.body).to include(user_request.status)
        expect(response.body).to include(admin_request.status)
      end
    end
  end

  describe "GET /requests/new" do
    context "when user is not logged in" do
      before {get new_request_path}

      include_examples "guest user redirection"
    end

    context "when user is logged in" do
      before do
        sign_in user
        create(:selected_book, user: user, book: book)
      end

      it "displays the new request form" do
        get new_request_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include(book.name)
      end
    end
  end

  describe "POST /requests" do
    context "when user is not logged in" do
      before {post requests_path}

      include_examples "guest user redirection"
    end

    context "when user is logged in" do
      before {sign_in user}

      context "with valid parameters" do
        let(:valid_params) do
          {
            request: {
              start_date: Date.tomorrow,
              end_date: Date.tomorrow + 5.days,
              selected_books: [book.id.to_s]
            }
          }
        end

        it "creates a new request" do
          create(:selected_book, user: user, book: book)

          expect {
            post requests_path, params: valid_params
          }.to change(Request, :count).by(1)

          expect(response).to redirect_to(root_path)
          expect(flash[:emerald]).to eq(I18n.t("success.request_created"))
        end

        it "deletes selected_books after creating request" do
          selected_book = create(:selected_book, user: user, book: book)

          expect {
            post requests_path, params: valid_params
          }.to change(SelectedBook, :count).by(-1)
        end

        it "creates requested_books after creating request" do
          selected_book = create(:selected_book, user: user, book: book)

          expect {
            post requests_path, params: valid_params
          }.to change(RequestedBook, :count).by(1)
        end
      end

      context "with invalid parameters" do
        let(:book_2) {create(:book, author: create(:author), publisher: create(:publisher), genre: create(:genre))}

        it "renders new with error when no books selected" do
          selected_book = create(:selected_book, user: user, book: book)

          post requests_path, params: {request: {borrower: user, start_date: Date.today, end_date: Date.today + 5, selected_books: []}}

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("Book must exist")
        end

        it "renders new with error when too many books selected" do
          book
          book_2

          allow(Settings.request).to receive(:allow_amount).and_return(1)
          post requests_path, params: {request: {start_date: Date.today, end_date: Date.today + 5, selected_books: [book.id, book_2.id]}}

          decoded_response = CGI.unescapeHTML(response.body)

          expect(response).to have_http_status(:unprocessable_entity)
          expect(decoded_response).to include(I18n.t("error.cant_borrow_more_than", allow_amount: 1))
        end

        it "renders new with error when user borrow more than a month" do
          book
          post requests_path, params: {request: {start_date: Date.today, end_date: Date.today + 31, selected_books: [book.id]}}

          decoded_response = CGI.unescapeHTML(response.body)

          expect(response).to have_http_status(:unprocessable_entity)
          expect(decoded_response).to include(I18n.t("error.borrow_more_than_a_month"))
        end
      end

      context "when user has unreturned books" do
        it "prevents creating new request" do
          create(:request, borrower: user, status: :borrowing)

          post requests_path, params: { request: { selected_books: [book.id] } }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include(I18n.t("error.has_unreturned_books"))
        end
      end
    end
  end

  describe "DELETE /requests/:id" do
    context "when user is not logged in" do
      before {post requests_path}

      include_examples "guest user redirection"
    end

    context "when user is logged in" do
      before {sign_in user}

      context "with pending request" do
        let!(:pending_request) {create(:request, borrower: user, status: :pending)}

        it "allows cancellation" do
          delete "/requests/#{pending_request.id}"

          expect(response).to redirect_to(root_url)
          expect(flash[:emerald]).to eq(I18n.t("success.request_cancelled"))
        end
      end

      context "with non-pending request" do
        let!(:borrowing_request) { create(:request, borrower: user, status: :borrowing) }

        it "prevents cancellation" do
          delete "/requests/#{borrowing_request.id}"

          expect(response).to redirect_to(root_url)
          expect(flash[:red]).to eq(I18n.t("error.can_only_cancel_pending_request"))
        end
      end

      context "when destroy fails" do
        before do
          allow_any_instance_of(Request).to receive(:destroy).and_return(false)
          delete "/requests/#{user_request.id}"
        end

        it "sets a flash message with error" do
          expect(flash[:red]).to eq(I18n.t("error.cant_cancel_request"))
        end

        it "redirects to the referer or root_url" do
          expect(response).to redirect_to(request.referer || root_url)
        end
      end
    end
  end

  describe "POST /requests/:id/handle" do
    let(:request_with_books) {create(:request, :with_books)}

    before {sign_in admin}

    context "when accepting request" do
      it "changes status to borrowing and updates book stock" do
        current_in_stock = request_with_books.books.first.in_stock
        post handle_request_path(locale: I18n.locale, id: request_with_books.id), params: {status: "borrowing"}

        request_with_books.reload
        expect(request_with_books.status).to eq("borrowing")
        expect(request_with_books.books.first.in_stock).to eq(current_in_stock - 1)
        expect(flash[:emerald]).to eq(I18n.t("success.changed_status", new_status: "borrowing"))
      end
    end

    context "when returning request" do
      let(:borrowing_request) {create(:request, :with_books, status: :borrowing)}

      it "changes status to returned and updates book stock" do
        current_in_stock = borrowing_request.books.first.in_stock
        post handle_request_path(locale: I18n.locale, id: borrowing_request.id), params: {status: "returned"}

        borrowing_request.reload
        expect(borrowing_request.status).to eq("returned")
        expect(borrowing_request.books.first.in_stock).to eq(current_in_stock + 1)
      end
    end

    context "when declining request" do
      it "requires a note" do
        post handle_request_path(locale: I18n.locale, id: request_with_books.id), params: {status: "declined"}

        expect(flash[:red]).to eq(I18n.t("error.missing_reason"))
      end

      it "declines with valid note" do
        post handle_request_path(locale: I18n.locale, id: request_with_books.id), params: {status: "declined", note: "Unavailable"}

        request_with_books.reload
        expect(request_with_books.status).to eq("declined")
        expect(request_with_books.note).to eq("Unavailable")
      end
    end

    context "when marking as overdue" do
      let(:borrowing_request) {create(:request, :with_books, status: :borrowing)}

      it "changes status to overdue" do
        post handle_request_path(locale: I18n.locale, id: borrowing_request.id), params: {status: "overdue"}

        borrowing_request.reload
        expect(borrowing_request.status).to eq("overdue")
      end
    end

    context "when transaction fails" do
      before {allow_any_instance_of(RequestsController).to receive(:change_status).and_raise(ActiveRecord::RecordInvalid, request_with_books)}

      it "sets flash with the error message and redirects to referer or root url" do
        error_message = "Something is wrong"
        allow(request_with_books.errors).to receive(:full_messages).and_return([error_message])

        post handle_request_path(locale: I18n.locale, id: request_with_books.id), params: { status: "borrowing" }

        expect(flash[:red]).to eq(error_message)
        expect(response).to redirect_to(request.referer || root_url)
      end
    end

    context "with demo user" do
      let(:demo_user) {create(:user, email: Settings.demo_email, phone: "0563396000")}
      let(:demo_request) {create(:request, borrower: demo_user)}

      it "sends email when status changes" do
        expect {
          post handle_request_path(locale: I18n.locale, id: demo_request.id), params: {status: "borrowing"}
        }.to change {ActionMailer::Base.deliveries.count}.by(1)
      end
    end

    context "with invalid status transition" do
      it "prevents invalid status change" do
        returned_request = create(:request, status: :returned)
        post handle_request_path(locale: I18n.locale, id: returned_request.id), params: {status: "borrowing"}

        expect(flash[:red]).to include(I18n.t("error.validate_status_allowed", new_status: "borrowing", current_status: "returned"))
      end
    end

    context "with non-existent request" do
      it "handles gracefully" do
        post handle_request_path(locale: I18n.locale, id: -1), params: {status: "borrowing"}

        expect(flash[:red]).to eq(I18n.t("error.request_not_found"))
      end
    end

    context "with request contains out of stock book" do
      let!(:request_with_books) {create(:request, :with_books)}

      before {request_with_books.books.first.update(in_stock: 0)}

      it "prevents changing request status" do
        post handle_request_path(locale: I18n.locale, id: request_with_books.id), params: {status: "borrowing"}

        expect(flash[:red]).to eq(I18n.t("error.contain_out_of_stock_books"))
        expect(request_with_books.reload.status).not_to eq("borrowing")
      end
    end
  end
end
