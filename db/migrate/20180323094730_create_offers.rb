class CreateOffers < ActiveRecord::Migration[5.0]
  def up
    create_table :offers do |t|
      t.references :contact, index: true
      t.string :title
      t.text :description
      t.string :area
      t.boolean :active, default: false, null: false
      t.string :image_url

      t.references :last_editor, references: :users
      t.references :creator, references: :users

      t.timestamps
    end

    create_table :offer_owners do |t|
      t.references :actor, index: true
      t.references :offer, index: true

      t.timestamps
    end
  end

  def down
    drop_table :offers
    drop_table :offer_owners
  end
end
