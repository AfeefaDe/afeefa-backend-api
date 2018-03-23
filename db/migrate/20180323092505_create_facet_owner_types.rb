class CreateFacetOwnerTypes < ActiveRecord::Migration[5.0]
  def up
    create_table :facet_owner_types do |t|
      t.references :facet, index: true
      t.string :owner_type
    end
  end
end
