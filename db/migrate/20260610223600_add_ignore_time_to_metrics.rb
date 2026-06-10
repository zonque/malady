class AddIgnoreTimeToMetrics < ActiveRecord::Migration[8.1]
  def change
    add_column :metrics, :ignore_time, :boolean, default: false, null: false
  end
end
