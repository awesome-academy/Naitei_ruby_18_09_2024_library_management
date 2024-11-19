class CreatePublishers < ActiveRecord::Migration[7.0]
  def change
    create_table :publishers do |t|
      t.string :name
      t.date :founded_date

      t.timestamps
    end
    add_index :publishers, :name
  end
end
