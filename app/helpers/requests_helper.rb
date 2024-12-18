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
      if all_requests_accessible?
        "view.requests_list.user_requests"
      else
        "view.requests_list.my_requests"
      end
    )
  end

  def all_requests_accessible?
    request.path.include?("all") && current_user.is_admin?
  end

  def reason reason
    reason || "-"
  end

  def is_processed? request
    if request.processor.present?
      link_to request.processor.name,
              request.processor,
              class: "text-blue-400 hover:text-blue-300 cursor-pointer"
    else
      "-"
    end
  end
end
