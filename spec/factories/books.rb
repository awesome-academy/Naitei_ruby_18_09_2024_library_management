FactoryBot.define do
  factory :book do
    name {Faker::Book.title}
    author_id {Author.pluck(:id).sample}
    publisher_id {Publisher.pluck(:id).sample}
    description {Faker::Lorem.paragraph}
    genre_id {Genre.pluck(:id).sample}
    in_stock {5}
  end
end
