class AddColumnsToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :title, :string
    add_column :organizations, :description, :text
  end
end
