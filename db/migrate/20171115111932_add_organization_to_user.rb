class AddOrganizationToUser < ActiveRecord::Migration[5.0]

  def change
    add_column :users, :organization, :string
  end

end
