class AddFacebookIdToEntry < ActiveRecord::Migration[5.0]
  def change
    add_column :orgas, :facebook_id, :string
    add_column :events, :facebook_id, :string
  end
end
