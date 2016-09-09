class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :lat
      t.string :lon

      t.string :street
      t.string :number
      t.string :addition
      t.string :zip
      t.string :city
      t.string :district
      t.string :state
      t.string :country

      t.boolean :displayed

      t.references :locatable, polymorphic: true, index: true

      t.timestamps null: false
    end
  end
end
