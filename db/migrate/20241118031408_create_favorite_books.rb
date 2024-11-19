class CreateFavoriteBooks < ActiveRecord::Migration[7.0]
  def change
    create_table :favorite_books do |t|
      t.bigint :user_id
      t.bigint :book_id

      t.timestamps
    end

    add_index :favorite_books, :user_id
    add_index :favorite_books, :book_id
    add_index :favorite_books, [:user_id, :book_id], unique: true
  end
end
