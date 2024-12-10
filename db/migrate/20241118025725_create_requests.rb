class CreateRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :requests do |t|
      t.integer :status, default: 0
      t.date :start_date
      t.date :end_date
      t.bigint :borrower_id
      t.bigint :processor_id

      t.timestamps
    end

    add_foreign_key :requests, :users, column: :borrower_id
    add_foreign_key :requests, :users, column: :processor_id
  end
end
