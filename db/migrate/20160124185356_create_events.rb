class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      # all entry data
      t.string :title
      t.string :description
      # image
      t.string :public_speaker
      t.string :location_type # way, point
      t.boolean :support_wanted
      t.datetime :activated_at
      t.datetime :deactivated_at
      t.integer :creator_id
      t.timestamps null: false

      # event specific data
      t.integer :meta_event_id
      t.datetime :date
    end
  end
end
