FactoryBot.define do
  factory :user do
    name {"Test user"}
    email {"test0@gmail.com"}
    phone {Faker::Number.number(digits: 10).to_s}
    password {"12345678"}
  end
end
