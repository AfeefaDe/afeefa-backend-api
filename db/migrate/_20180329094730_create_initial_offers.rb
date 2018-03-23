class CreateInitialOffers < ActiveRecord::Migration[5.0]
  def up
    Orga.all.each do |orga|
      offer = DataModules::Offer::Offer.create(
        title: orga.title,
        description: orga.short_description,
        actor_id: orga.id
      )
    end
  end

  def down
    DataModules::Offer::Offer.destroy_all
  end
end
