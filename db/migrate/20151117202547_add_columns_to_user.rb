class AddColumnsToUser < ActiveRecord::Migration
  def change
    add_column :users, :forename, :string
    add_column :users, :surname, :string
  end
end
