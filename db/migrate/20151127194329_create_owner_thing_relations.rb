class CreateOwnerThingRelations < ActiveRecord::Migration
  def change
    create_table :owner_thing_relations do |t|

      t.references :ownable, polymorphic: true, index: true
      t.references :thingable, polymorphic: true, index: true

      t.timestamps null: false
    end
  end
end
