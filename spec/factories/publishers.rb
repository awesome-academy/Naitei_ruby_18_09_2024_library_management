FactoryBot.define do
  factory :publisher do
    name {"NXB Kim Dong"}
    founded_date {Faker::Date.between(from: "1900-01-01", to: "2000-12-31")}
  end
end
