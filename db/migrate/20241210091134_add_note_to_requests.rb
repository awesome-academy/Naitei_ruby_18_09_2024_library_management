class AddNoteToRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :requests, :note, :string
  end
end
