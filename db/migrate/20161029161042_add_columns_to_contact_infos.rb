class AddColumnsToContactInfos < ActiveRecord::Migration[5.0]
  def change
    add_column :contact_infos, :mail, :string
    add_column :contact_infos, :phone, :string
    add_column :contact_infos, :contact_person, :string
    remove_column :contact_infos, :type
    remove_column :contact_infos, :content
  end
end
