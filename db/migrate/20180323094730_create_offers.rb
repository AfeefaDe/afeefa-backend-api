class CreateOffers < ActiveRecord::Migration[5.0]
  def up
    create_table :offers do |t|
      t.string :title
      t.text :description

      t.timestamps
    end

    create_table :owner_offers do |t|
      t.references :actor, index: true
      t.references :offer, index: true

      t.timestamps
    end
  end

  def down
    drop_table :offers
    drop_table :owner_offers
  end
end
