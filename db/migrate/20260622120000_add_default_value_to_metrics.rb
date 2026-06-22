class AddDefaultValueToMetrics < ActiveRecord::Migration[8.1]
  def change
    add_column :metrics, :default_value, :string
  end
end
