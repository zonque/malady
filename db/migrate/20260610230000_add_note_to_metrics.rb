class AddNoteToMetrics < ActiveRecord::Migration[8.1]
  def change
    add_column :metrics, :note, :string
  end
end
