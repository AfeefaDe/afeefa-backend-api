class RenameOrganizationToOrga < ActiveRecord::Migration
  def change
    rename_table :organizations, :orgas
    rename_table :organization_category_relations, :orga_category_relations

    rename_column :roles, :organization_id, :orga_id
    rename_column :orga_category_relations, :organization_id, :orga_id
  end
end
