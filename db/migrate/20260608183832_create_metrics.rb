class CreateMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :metrics do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :slug
      t.text :description
      t.string :data_type
      t.string :unit
      t.text :enum_options, null: false, default: "[]"
      t.string :color
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :metrics, [:user_id, :slug], unique: true
    add_index :metrics, [:user_id, :position]
  end
end
