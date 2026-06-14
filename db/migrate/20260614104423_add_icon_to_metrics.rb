class AddIconToMetrics < ActiveRecord::Migration[8.1]
  def change
    add_column :metrics, :icon, :string
  end
end
