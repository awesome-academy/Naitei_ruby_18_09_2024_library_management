class CreateSelectedBooks < ActiveRecord::Migration[7.0]
  def change
    create_table :selected_books do |t|
      t.bigint :user_id
      t.bigint :book_id

      t.timestamps
    end

    add_index :selected_books, :user_id
    add_index :selected_books, :book_id
    add_index :selected_books, [:user_id, :book_id], unique: true
  end
end
