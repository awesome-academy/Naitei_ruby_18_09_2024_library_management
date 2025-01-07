require "rails_helper"

RSpec.describe Request, type: :model do
  let(:borrower) { create(:user) }
  let(:processor) { create(:user) }
  let(:book) { create(:book) }
  let(:request) do
    described_class.new(
      borrower: borrower,
      start_date: Date.today,
      end_date: Date.today + 7.days,
      status: :pending
    )
  end

  describe "associations" do
    it "belongs to a borrower" do
      expect(request).to belong_to(:borrower).class_name("User")
    end

    it "belongs to a processor (optional)" do
      expect(request).to belong_to(:processor).class_name("User").optional
    end

    it "has many requested_books" do
      expect(request).to have_many(:requested_books).dependent(:destroy)
    end

    it "has many books through requested_books" do
      expect(request).to have_many(:books).through(:requested_books)
    end
  end

  describe "validations" do
    it "validates presence of start_date" do
      expect(request).to validate_presence_of(:start_date)
    end

    it "validates presence of end_date" do
      expect(request).to validate_presence_of(:end_date)
    end

    context "status validation" do
      it "allows only valid statuses" do
        valid_statuses = Request.statuses.keys
        valid_statuses.each do |status|
          request.status = status
          expect(request).to be_valid
        end
      end

      it "raises ArgumentError when assigning invalid status" do
        expect {request.status = :invalid_status}.to raise_error(ArgumentError, "'invalid_status' is not a valid status")
      end
    end

    context "custom validations" do
      it "is invalid if start_date is in the past" do
        request.start_date = Date.yesterday
        expect(request).not_to be_valid
        expect(request.errors[:base]).to include(I18n.t("error.past_start_date"))
      end

      it "is invalid if borrow time exceeds one month" do
        request.end_date = request.start_date + 35.days
        expect(request).not_to be_valid
        expect(request.errors[:base]).to include(I18n.t("error.borrow_more_than_a_month"))
      end

      it "is invalid if start_date is after end_date" do
        request.start_date = Date.today + 10.days
        request.end_date = Date.today + 5.days
        expect(request).not_to be_valid
        expect(request.errors[:base]).to include(I18n.t("error.start_date_after_end_date"))
      end
    end
  end

  describe "scopes" do
    let!(:pending_request) {create(:request, status: :pending, borrower: borrower,
                                   start_date: Date.today, end_date: Date.today + 1, created_at: Time.current)}
    let!(:borrowing_request) {create(:request, status: :borrowing, borrower: borrower,
                                     start_date: Date.today, end_date: Date.today + 1, created_at: Time.current + 1)}
    let!(:declined_request) {create(:request, status: :declined, borrower: borrower,
                             start_date: Date.today, end_date: Date.today + 1, created_at: Time.current + 2)}

    it ".uncompleted returns requests with uncompleted statuses" do
      expect(Request.uncompleted).to contain_exactly(pending_request, borrowing_request)
    end

    it ".newest orders requests by created_at desc" do
      expect(Request.newest.first).to eq(declined_request)
      expect(Request.newest.last).to eq(pending_request)
    end

    it ".not_declined_or_returned excludes declined or returned requests" do
      expect(Request.not_declined_or_returned).not_to include(declined_request)
    end
  end

  describe "enums" do
    it "defines statuses correctly" do
      expect(Request.statuses).to eq(
        "pending" => 0,
        "borrowing" => 1,
        "overdue" => 2,
        "declined" => 3,
        "returned" => 4
      )
    end
  end

  describe "callbacks" do
    it "triggers custom validations on :create" do
      request.end_date = Date.yesterday
      expect(request.valid?(:create)).to be false
      expect(request.errors[:base]).to include(I18n.t("error.start_date_after_end_date"))
    end
  end

  describe "#want_to_decline?" do
    it "returns true when status is declined" do
      request.status = :declined
      expect(request.send(:want_to_decline?)).to be true
    end

    it "returns false when status is not declined" do
      request.status = :pending
      expect(request.send(:want_to_decline?)).to be false
    end
  end
end
