class RenameFacebookToSocialMedia < ActiveRecord::Migration[5.0]

  def change
    rename_column :contact_infos, :facebook, :social_media
  end

end
