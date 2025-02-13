class HandleRequestService
  attr_reader :user, :request, :new_status, :note, :errors

  def initialize user, request, new_status, note = nil
    @user = user
    @request = request
    @new_status = new_status.to_sym
    @note = note
    @errors = []
  end

  def call
    return false unless new_status_is_valid? && has_out_of_stock_book?

    case @new_status
    when :borrowing, :returned
      process_accept_or_return_request
    when :declined
      return false unless process_decline_request?
    when :overdue
      change_status
    end

    send_mail and return true
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.record.errors.full_messages.join(", ")
    false
  end

  private

  def new_status_is_valid?
    if Request::ALLOWED_ACTIONS[@request.status].include? @new_status
      true
    else
      @errors << I18n.t("error.validate_status_allowed",
                        current_status: @request.status,
                        new_status: @new_status)
      false
    end
  end

  def has_out_of_stock_book?
    if @request.books.with_zero_in_stock.exists? || @new_status == :declined
      true
    else
      @errors << I18n.t("error.contain_out_of_stock_books")
      false
    end
  end

  def change_status
    @request.update! status: new_status, processor: user
  end

  def change_book_amount amount
    @request.books.each do |book|
      book.update!(in_stock: book.in_stock + amount)
    end
  end

  def process_accept_or_return_request
    ActiveRecord::Base.transaction do
      change_status
      amount = (@new_status == :borrowing ? -1 : 1)
      change_book_amount(amount)
    end
  end

  def process_decline_request?
    if note.present?
      @request.update! status: new_status, note:, processor: user
      true
    else
      @errors << I18n.t("error.missing_reason")
      false
    end
  end

  def send_mail
    return unless @request.borrower.email == Settings.demo_email

    SendEmailJob.perform_later(@request.borrower.id, @new_status.to_s)
  end
end
