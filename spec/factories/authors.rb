FactoryBot.define do
  factory :author do
    name {
      begin
        generated_name = Faker::Book.author
      end while generated_name.length >= 30
      generated_name
    }
    birthday {Faker::Date.birthday(min_age: 25, max_age: 80)}
    biography {Faker::Lorem.paragraph}
  end
end
