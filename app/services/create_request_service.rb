class CreateRequestService
  attr_reader :user, :params, :selected_books, :errors, :request

  def initialize user, params
    @user = user
    @params = params
    @selected_books = params[:selected_books]&.map(&:to_i)
    @errors = []
  end

  def call
    return false if has_unreturned_books? || invalid_borrow_amount?

    ActiveRecord::Base.transaction do
      create_borrow_request!
      delete_selected_books!
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.record.errors.full_messages.join(", ")
    false
  end

  private

  def invalid_borrow_amount?
    is_book_present = @selected_books.present?
    is_over_size = @selected_books&.size.to_i > Settings.request.allow_amount
    return false if is_book_present && !is_over_size

    @errors << I18n.t("error.cant_borrow_more_than",
                      allow_amount: Settings.request.allow_amount)
    @errors = [I18n.t("error.less_than_a_book")] unless is_book_present
    true
  end

  def has_unreturned_books?
    return false if @user.borrow_requests.uncompleted.blank?

    @errors = [I18n.t("error.has_unreturned_books")]
    true
  end

  def create_borrow_request!
    @request = @user.borrow_requests.create!(
      start_date: params[:start_date],
      end_date: params[:end_date]
    )
    @request.requested_books.create!(build_book_params)
  end

  def delete_selected_books!
    @user.selected_books.by_book_ids(@selected_books).delete_all
  end

  def build_book_params
    @selected_books&.map{|book_id| {book_id:}}
  end
end
