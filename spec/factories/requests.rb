FactoryBot.define do
  factory :request do
    status {:pending}
    start_date {Date.tomorrow}
    end_date {Date.tomorrow + 5.days}
    association :borrower, factory: :user

    trait :with_books do
      after(:create) do |request|
        book = create(:book, author: create(:author), publisher: create(:publisher), genre: create(:genre))
        create(:requested_book, request: request, book: book)
      end
    end
  end
end
