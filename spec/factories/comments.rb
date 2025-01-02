FactoryBot.define do
  factory :comment do
    content {Faker::Lorem.sentence}
    user_id {User.pluck(:id).sample}
    book_id {Book.pluck(:id).sample}
  end
end
