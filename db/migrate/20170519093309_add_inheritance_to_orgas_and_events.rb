class AddInheritanceToOrgasAndEvents < ActiveRecord::Migration[5.0]

  def change
    add_column :orgas, :inheritance, :json
    add_column :events, :inheritance, :json
  end

end
