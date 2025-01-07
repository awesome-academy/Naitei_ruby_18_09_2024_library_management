require "rails_helper"

RSpec.describe "Api::V1::Books", type: :request do
  let(:user)       {create(:user)}
  let!(:author)    {create(:author)}
  let!(:publisher) {create(:publisher)}
  let!(:genre)     {create(:genre)}
  let!(:book)      {create(:book, author: author, publisher: publisher, genre: genre, in_stock: 2)}
  let!(:comments)  {create(:comment, user: user, book: book)}

  describe "GET /api/v1/books" do
    context "when not use search params" do
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

    context "when use search params" do
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
    context "with valid parameters" do
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

      it "creates a new book" do
        expect {
          post "/api/v1/books", params: valid_params
        }.to change(Book, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(json_response["message"]).to eq(I18n.t("success.book_created"))
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          book: {
            name: "",
            description: "A great book"
          }
        }
      end

      it "does not create a new book and returns errors" do
        expect {
          post "/api/v1/books", params: invalid_params
        }.not_to change(Book, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"]).to include("Name can't be blank")
      end
    end
  end

  describe "PATCH/PUT /api/v1/books/:id" do
    context "with valid parameters" do
      let(:update_params) do
        {
          book: {name: "Updated Name"}
        }
      end

      it "updates the book details" do
        patch "/api/v1/books/#{book.id}", params: update_params
        expect(response).to have_http_status(:ok)
        expect(json_response["message"]).to eq(I18n.t("success.book_updated"))
        expect(book.reload.name).to eq("Updated Name")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          book: {name: ""}
        }
      end

      it "does not update the book and returns errors" do
        patch "/api/v1/books/#{book.id}", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"]).to include("Name can't be blank")
      end
    end
  end

  describe "DELETE /api/v1/books/:id" do
    it "deletes the book" do
      expect {
        delete "/api/v1/books/#{book.id}"
      }.to change(Book, :count).by(-1)
      expect(response).to have_http_status(:ok)
      expect(json_response["message"]).to eq(I18n.t("success.book_deleted"))
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
