class CreateAuthors < ActiveRecord::Migration[7.0]
  def change
    create_table :authors do |t|
      t.string :name
      t.string :biography
      t.date :birthday

      t.timestamps
    end
    add_index :authors, :name
  end
end
