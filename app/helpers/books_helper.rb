module BooksHelper
  def book_cover book
    book.cover.presence || Settings.book.default_cover
  end

  def get_index counter
    (@pagy.page - 1) * @pagy.limit + counter + 1
  end

  def borrowable book
    t book.borrowable ? "text.borrowable" : "text.unborrowable"
  end

  def is_operator_selected? operator
    params[:q] && params[:q][:amount_operator] == operator ? true : false
  end

  def is_borrowable_checked?
    params.dig(:q, :can_borrow_eq) != "0"
  end

  def is_or_query?
    params.dig(:q, :or_query_eq) != "0"
  end

  def user_role
    if current_user.blank?
      :guest
    elsif !current_user.is_admin?
      :user
    else
      :admin
    end
  end
end
