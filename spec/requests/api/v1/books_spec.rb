require "rails_helper"
require Rails.root.join("lib/json_web_token")

RSpec.describe "Api::V1::Books", type: :request do
  let(:user)            {create(:user)}
  let(:admin)           {create(:user, is_admin: true, email: "admin@gmail.com", phone: "0123456780")}
  let!(:author)         {create(:author)}
  let!(:publisher)      {create(:publisher)}
  let!(:genre)          {create(:genre)}
  let!(:book)           {create(:book, author: author, publisher: publisher, genre: genre, in_stock: 2)}
  let!(:comments)       {create(:comment, user: user, book: book)}
  let(:headers)         {{"Authorization" => "Bearer #{generate_jwt(user)}"}}
  let(:admin_headers)   {{"Authorization" => "Bearer #{generate_jwt(admin)}"}}
  let(:expired_headers) {{"Authorization" => "Bearer #{expired_jwt(admin)}"}}

  before do
    allow(Book.__elasticsearch__).to receive(:create_index!).and_return(true)
    allow(Book.__elasticsearch__).to receive(:import).and_return(true)
    allow(Book.__elasticsearch__).to receive(:refresh_index!).and_return(true)
  end

  describe "GET /api/v1/books" do
    context "when no search params are provided" do
      it "returns a list of books" do
        get "/api/v1/books"

        expect(response).to have_http_status(:ok)
        expect(json_response.size).to eq(1)
        expect(json_response[0]["name"]).to eq(book.name)
      end

      it "returns books sorted by name" do
        create(:book, name: "A Book", author: author, publisher: publisher, genre: genre)

        get "/api/v1/books"

        expect(response).to have_http_status(:ok)
        expect(json_response.first["name"]).to eq("A Book")
      end
    end

    context "when search params are provided" do
      let!(:book_2) {create(:book, author: author, publisher: publisher, genre: genre, in_stock: 5)}
      let!(:search_params) do
        {
          q: {
            amount_operator: "lt",
            in_stock: 5
          }
        }
      end

      it "returns matching books" do
        get "/api/v1/books", params: search_params

        expect(response).to have_http_status(:ok)
        expect(json_response.size).to eq(1)
        expect(json_response[0]["name"]).to eq(book.name)
      end
    end
  end

  describe "GET /api/v1/books/:id" do
    context "when the book exists" do
      it "returns the book details" do
        get "/api/v1/books/#{book.id}"

        expect(response).to have_http_status(:ok)
        expect(json_response["name"]).to eq(book.name)
        expect(json_response["author_name"]).to eq(author.name)
        expect(json_response["comments"].size).to eq(1)
      end
    end

    context "when the book does not exist" do
      it "returns a 404 error" do
        get "/api/v1/books/-1"
        expect(response).to have_http_status(:not_found)
        expect(json_response["error"]).to eq(I18n.t("error.book_not_found"))
      end
    end
  end

  describe "POST /api/v1/books" do
    let(:valid_params) do
      {
        book: {
          name: "New Book",
          description: "A great book",
          in_stock: 5,
          borrowable: true,
          author_id: author.id,
          publisher_id: publisher.id,
          genre_id: genre.id
        }
      }
    end

    context "when authenticated as admin" do
      context "with valid params" do
        it "creates a new book" do
          expect {
            post "/api/v1/books", params: valid_params, headers: admin_headers
          }.to change(Book, :count).by(1)

          expect(response).to have_http_status(:created)
          expect(json_response["message"]).to eq(I18n.t("success.book_created"))
        end
      end

      context "with invalid params" do
        let(:invalid_params) do
          {
            book: {
              name: "",
              description: "A great book",
              in_stock: 1,
              borrowable: true,
              author_id: -1,
              publisher_id: publisher.id,
              genre_id: genre.id
            }
          }
        end

        it "does not create a new book and returns errors" do
          expect {
            post "/api/v1/books", params: invalid_params, headers: admin_headers
          }.not_to change(Book, :count)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response["errors"]).to include("Name can't be blank")
        end
      end
    end

    context "when authenticated as user" do
      before {post "/api/v1/books", params: valid_params, headers: headers}

      include_examples "when authenticated as user"
    end

    context "when provided with invalid token" do
      before {post "/api/v1/books", params: valid_params, headers: {"Authorization" => "Bearer invalid.jwt"}}

      include_examples "when provided with invalid token"
    end

    context "when token has expired" do
      before {post "/api/v1/books", params: valid_params, headers: expired_headers}

      include_examples "when token has expired"
    end
  end

  describe "PATCH /api/v1/books/:id" do
    let(:update_params) do
      {
        book: {name: "Updated Name"}
      }
    end

    context "when authenticated as admin" do
      context "with valid params" do
        it "updates the book details" do
          patch "/api/v1/books/#{book.id}", params: update_params, headers: admin_headers
          expect(response).to have_http_status(:ok)
          expect(json_response["message"]).to eq(I18n.t("success.book_updated"))
          expect(book.reload.name).to eq("Updated Name")
        end
      end

      context "with invalid params" do
        let(:invalid_params) do
          {
            book: {name: ""}
          }
        end

        it "does not update the book and returns errors" do
          patch "/api/v1/books/#{book.id}", params: invalid_params, headers: admin_headers
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response["errors"]).to include("Name can't be blank")
        end
      end
    end

    context "when authenticated as user" do
      before {patch "/api/v1/books/#{book.id}", params: update_params, headers: headers}

      include_examples "when authenticated as user"
    end

    context "when provided with invalid token" do
      before {patch "/api/v1/books/#{book.id}", params: update_params, headers: {"Authorization" => "Bearer invalid.jwt"}}

      include_examples "when provided with invalid token"
    end

    context "when token has expired" do
      before {patch "/api/v1/books/#{book.id}", params: update_params, headers: expired_headers}

      include_examples "when token has expired"
    end
  end

  describe "DELETE /api/v1/books/:id" do
    context "when authenticated as admin" do
      it "deletes the book" do
        expect {
          delete "/api/v1/books/#{book.id}", headers: admin_headers
        }.to change(Book, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(json_response["message"]).to eq(I18n.t("success.book_deleted"))
      end
    end

    context "when authenticated as user" do
      before {delete "/api/v1/books/#{book.id}", headers: headers}

      include_examples "when authenticated as user"
    end

    context "when provided with invalid token" do
      before {delete "/api/v1/books/#{book.id}", headers: {"Authorization" => "Bearer invalid.jwt"}}

      include_examples "when provided with invalid token"
    end

    context "when token has expired" do
      before {delete "/api/v1/books/#{book.id}", headers: expired_headers}

      include_examples "when token has expired"
    end
  end

  def json_response
    JSON.parse(response.body)
  end

  def generate_jwt user
    JsonWebToken.encode(id: user.id)
  end

  def expired_jwt user
    JsonWebToken.encode({id: user.id}, Time.current - 1)
  end
end
