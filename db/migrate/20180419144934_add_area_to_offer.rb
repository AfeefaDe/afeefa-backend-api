class AddAreaToOffer < ActiveRecord::Migration[5.0]
  def change
    add_column :offers, :area, :string, after: :description

    DataModules::Offer::Offer.all.each do |offer|
      owner = offer.owners.first
      if owner
        offer.area = owner.area
        offer.save!
      end
    end
  end
end
