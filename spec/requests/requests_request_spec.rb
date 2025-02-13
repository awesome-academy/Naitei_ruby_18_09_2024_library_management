require "rails_helper"

RSpec.describe "RequestsController", type: :request do
  let(:user)          {create(:user)}
  let(:admin)         {create(:user, email: "admin@gmail.com", phone: "1112223335", is_admin: true)}
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

        context "when the CreateRequestService call is successful" do
          before do
            service = instance_double(CreateRequestService, call: true, errors: [])
            allow(CreateRequestService).to receive(:new)
              .with(user, kind_of(ActionController::Parameters))
              .and_return(service)
          end

          it "sets a success flash message and redirects to root_path with status see_other (303)" do
            post requests_path, params: { request: valid_params }
            expect(flash[:emerald]).to eq(I18n.t("success.request_created"))
            expect(response).to redirect_to(root_path)
            expect(response.status).to eq(303)
          end
        end

        context "when the CreateRequestService call fails" do
          before do
            service = instance_double(CreateRequestService, call: false, errors: ["Something went wrong"])
            allow(CreateRequestService).to receive(:new)
              .with(user, kind_of(ActionController::Parameters))
              .and_return(service)
          end

          it "renders the flash.now error and a 422 status" do
            post requests_path, params: { request: valid_params }
            expect(flash.now[:red]).to eq("Something went wrong")
            expect(response.status).to eq(422)
          end
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
    let(:request_with_books) { create(:request, :with_books) }
    let(:status_param) { "borrowing" }
    let(:note_param) { "Note for request" }

    before { sign_in admin }

    context "when the request exists" do
      before do
        allow(Request).to receive_message_chain(:includes, :find_by)
          .with(id: request_with_books.id.to_s)
          .and_return(request_with_books)
      end

      context "when the HandleRequestService call is successful" do
        before do
          service = instance_double(HandleRequestService, call: true, errors: [])
          allow(HandleRequestService).to receive(:new)
            .with(admin, request_with_books, status_param, note_param)
            .and_return(service)
        end

        it "sets a success flash with status see_other (303)" do
          post handle_request_path(locale: I18n.locale, id: request_with_books.id), params: { status: status_param, note: note_param }
          expect(flash[:emerald]).to eq(I18n.t("success.changed_status", new_status: status_param))
          expect(response.status).to eq(303)
        end
      end

      context "when the HandleRequestService call fails" do
        before do
          service = instance_double(HandleRequestService, call: false, errors: ["Failed to update"])
          allow(HandleRequestService).to receive(:new)
            .with(admin, request_with_books, status_param, note_param)
            .and_return(service)
        end

        it "sets an error flash" do
          post handle_request_path(locale: I18n.locale, id: request_with_books.id), params: {status: status_param, note: note_param}
          expect(flash[:red]).to eq("Failed to update")
        end
      end
    end

    context "when the request does not exist" do
      before do
        allow(Request).to receive_message_chain(:includes, :find_by)
          .with(id: "non-existent")
          .and_return(nil)
      end

      it "sets an error flash" do
        post handle_request_path(locale: I18n.locale, id: "non-existent"), params: {status: status_param, note: note_param}
        expect(flash[:red]).to eq(I18n.t("error.request_not_found"))
      end
    end
  end
end
