class CreateDataPoints < ActiveRecord::Migration[8.1]
  def change
    create_table :data_points do |t|
      t.references :metric, null: false, foreign_key: true
      t.datetime :recorded_at
      t.text :note
      t.text :value_text
      t.decimal :value_decimal, precision: 20, scale: 6
      t.boolean :value_boolean

      t.timestamps
    end
    add_index :data_points, [:metric_id, :recorded_at]
  end
end
