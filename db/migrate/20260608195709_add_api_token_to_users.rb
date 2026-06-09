class AddApiTokenToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :api_token, :string
    add_index :users, :api_token, unique: true
    User.reset_column_information
    User.where(api_token: nil).find_each do |u|
      u.update_column(:api_token, User.generate_api_token)
    end
    change_column_null :users, :api_token, false
  end

  def down
    remove_column :users, :api_token
  end
end
