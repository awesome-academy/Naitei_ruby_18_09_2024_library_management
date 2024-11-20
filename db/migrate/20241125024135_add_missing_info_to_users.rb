class AddMissingInfoToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :password_digest, :string
    add_column :users, :phone, :string
    add_index :users, :phone, unique: true
  end
end
