class AddDeviseToUsers < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      t.string   :encrypted_password, null: false, default: ""
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer  :failed_attempts, null: false, default: 0
      t.string   :unlock_token
      t.datetime :locked_at
    end
    add_index :users, :reset_password_token, unique: true
    add_index :users, :unlock_token, unique: true
  end
end
