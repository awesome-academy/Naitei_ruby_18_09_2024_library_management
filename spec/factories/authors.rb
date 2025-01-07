FactoryBot.define do
  factory :author do
    name {"Author Name"}
    birthday {Faker::Date.birthday(min_age: 25, max_age: 80)}
    biography {Faker::Lorem.paragraph}
  end
end
