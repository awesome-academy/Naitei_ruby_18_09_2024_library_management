# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
User.create!(name: "H503",
            email: "h503@gmail.com",
            password: "12345678",
            password_confirmation: "12345678",
            phone: "0563396500",
            is_admin: true)

5.times do |n|
  name = Faker::Name.name
  email = "user#{n+1}@gmail.com"
  phone = "111111111#{n+1}"
  password = "12345678"
  User.create!(name: name,
              email: email,
              password: password,
              password_confirmation: password,
              phone: phone)
end

10.times do
  Author.create(
    name: Faker::Book.author,
    birthday: Faker::Date.birthday(min_age: 25, max_age: 80),
    biography: Faker::Lorem.paragraph
  )

  Publisher.create(
    name: Faker::Company.name,
    founded_date: Faker::Date.between(from: '1900-01-01', to: '2000-12-31')
  )

  Genre.create(
    name: Faker::Book.genre,
    description: Faker::Lorem.sentence
  )
end

p "Seeded authors, publishers, genres"

50.times do
  Book.create(
    name: Faker::Book.title,
    author_id: Author.pluck(:id).sample,
    publisher_id: Publisher.pluck(:id).sample,
    description: Faker::Lorem.paragraph,
    genre_id: Genre.pluck(:id).sample,
    in_stock: 5
  )
end

p "Seeded books"

Book.all.each do |book|
  6.times do
    Comment.create!(
      content: Faker::Lorem.sentence,
      user_id: User.pluck(:id).sample,
      book_id: book.id
    )
  end
end

p "Seeded comments"
