class AddFaxToContactInfos < ActiveRecord::Migration[5.0]
  def change
    add_column :contact_infos, :fax, :string
  end
end
