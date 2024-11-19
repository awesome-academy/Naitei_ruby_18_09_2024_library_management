class CreateRequestedBooks < ActiveRecord::Migration[7.0]
  def change
    create_table :requested_books do |t|
      t.bigint :request_id
      t.bigint :book_id

      t.timestamps
    end

    add_index :requested_books, :request_id
    add_index :requested_books, :book_id
    add_index :requested_books, [:request_id, :book_id], unique: true
  end
end
