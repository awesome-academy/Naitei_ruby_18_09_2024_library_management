module RequestsHelper
  def requested_book_names request
    safe_join(request.books.map{|book| h(book.name)}, tag.br)
  end

  def calculate_index counter
    (@pagy.page - 1) * @pagy.limit + counter + 1
  end

  def status_class status
    case status
    when "pending"
      "bg-yellow-500"
    when "borrowing"
      "bg-emerald-500"
    when "declined"
      "bg-gray-500"
    when "returned"
      "bg-blue-500"
    else
      "bg-red-500"
    end
  end

  def title
    t(
      if current_user.is_admin?
        "view.requests_list.user_requests"
      else
        "view.requests_list.my_requests"
      end
    )
  end
end
