FactoryBot.define do
  factory :genre do
    name {Faker::Book.genre}
    description {Faker::Lorem.sentence}
  end
end
