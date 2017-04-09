class AddMissingAttributesToContactInfo < ActiveRecord::Migration[5.0]
  def change
    add_column :contact_infos, :opening_hours, :string
    add_column :locations, :directions, :string
  end
end
