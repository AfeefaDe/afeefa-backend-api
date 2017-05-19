class AddInheritanceToOrgasAndEvents < ActiveRecord::Migration[5.0]

  def change
    add_column :orgas, :inheritance, :string
    add_column :events, :inheritance, :string
  end

end
