class BooksController < ApplicationController
  include BooksHelper

  load_resource
  before_action :create_selected_book_object, if: ->{current_user.present?}
  before_action :create_comment_object,
                only: :show, if: ->{current_user.present?}

  def index
    @q = Book.ransack(search_params, auth_object: user_role)
    @q.sorts = "name asc" if @q.sorts.empty?
    @pagy, @books = pagy @q.result
                           .includes(:author, cover_attachment: :blob),
                         limit: Settings.default_pagination
    @highlighted_books = {}
  end

  def show
    @pagy, @comments = pagy Comment.includes(:user).by_book(@book.id),
                            limit: Settings.default_pagination
  end

  def search
    @query = params[:query]&.strip

    if @query.present?
      handle_search_results
    else
      handle_default_results
    end

    prepare_sort_and_render
  rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
    handle_search_error e.message
  end

  def autocomplete
    query = params[:query].downcase
    book = Book.autocomplete(query).response[:hits][:hits][0]

    if book
      name = book.dig(:highlight, :name)&.first
      author_name = book.dig(:highlight, :author_name)&.first

      render json: {
        matched_part: matched_part(query, (name || author_name))
      }
    else
      render json: {matched_part: nil}
    end
  end

  rescue_from ActiveRecord::RecordNotFound do
    flash[:red] = t "error.book_not_found"
    redirect_to request.referer || root_path
  end

  private

  def search_params
    update_in_stock_option if contain_in_stock_option?
    apply_or_query
  end

  def update_in_stock_option
    in_stock_option = "in_stock_#{params[:q][:amount_operator]}".to_sym
    params[:q][in_stock_option] = params[:q][:in_stock]
  end

  def apply_or_query
    is_or_query? ? params[:q].try(:merge, m: "or") : params[:q]
  end

  def contain_in_stock_option?
    params.dig(:q, :amount_operator) && params.dig(:q, :in_stock)
  end

  def matched_part query, term
    term = term.gsub(%r{</?em>}, "")
    start_index = term.downcase.index query
    term[start_index + query.length..]
  end

  def create_selected_book_object
    @selected_book = current_user.selected_books.build
  end

  def create_comment_object
    @comment = current_user.comments.build
  end

  def handle_search_results
    search_results = Book.elasticsearch_search @query
    books_with_highlights = search_results.response[:hits][:hits]

    @pagy, @books = pagy(
      search_results.records.includes(:author, cover_attachment: :blob),
      limit: Settings.default_pagination
    )
    @highlighted_books = extract_highlighted_books books_with_highlights
  end

  def handle_default_results
    @pagy, @books = pagy(
      Book.includes(:author, cover_attachment: :blob),
      limit: Settings.default_pagination
    )
    @highlighted_books = {}
  end

  def extract_highlighted_books books_with_highlights
    books_with_highlights.each_with_object({}) do |hit, highlights|
      highlights[hit[:_id].to_i] = hit[:highlight]
    end
  end

  def prepare_sort_and_render
    @q = Book.ransack(search_params, auth_object: user_role)
    @q.sorts = "name asc" if @q.sorts.empty?
    render :index
  end

  def handle_search_error msg
    flash[:red] = msg
    redirect_to root_path
  end
end
