class ChangeLengthOfPossibleLongStringsTo1000 < ActiveRecord::Migration[5.0]

  def change
    change_column :annotation_categories, :title, :string, limit: 1000

    change_column :categories, :title, :string, limit: 1000

    change_column :contact_infos, :mail, :string, limit: 1000
    # change_column :contact_infos, :phone, :string, limit: 1000
    # change_column :contact_infos, :fax, :string, limit: 1000
    change_column :contact_infos, :contact_person, :string, limit: 1000
    change_column :contact_infos, :web, :string, limit: 1000
    change_column :contact_infos, :social_media, :string, limit: 1000
    change_column :contact_infos, :spoken_languages, :string, limit: 1000

    change_column :events, :title, :string, limit: 1000
    change_column :events, :public_speaker, :string, limit: 1000
    change_column :events, :media_url, :string, limit: 1000
    change_column :events, :tags, :string, limit: 1000
    change_column :events, :area, :string, limit: 1000

    change_column :locations, :lat, :string, limit: 1000
    change_column :locations, :lon, :string, limit: 1000
    change_column :locations, :street, :string, limit: 1000
    change_column :locations, :placename, :string, limit: 1000
    change_column :locations, :city, :string, limit: 1000
    change_column :locations, :district, :string, limit: 1000
    change_column :locations, :country, :string, limit: 1000
    change_column :locations, :directions, :string, limit: 1000

    change_column :orgas, :title, :string, limit: 1000
    change_column :orgas, :media_url, :string, limit: 1000
    change_column :orgas, :tags, :string, limit: 1000
    change_column :orgas, :area, :string, limit: 1000

    change_column :roles, :title, :string, limit: 1000

    change_column :translation_caches, :title, :string, limit: 1000

    change_column :users, :email, :string, default: '', null: false, limit: 1000
    change_column :users, :encrypted_password, :string, default: '', null: false, limit: 1000
    change_column :users, :reset_password_token, :string, limit: 1000
    change_column :users, :forename, :string, limit: 1000
    change_column :users, :surname, :string, limit: 1000
    change_column :users, :area, :string, limit: 1000

    remove_column :contact_infos, :internal_id
    remove_column :locations, :internal_id
  end

end
