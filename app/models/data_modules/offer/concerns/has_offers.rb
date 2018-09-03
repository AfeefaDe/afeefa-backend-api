module DataModules::Offer::Concerns::HasOffers

  extend ActiveSupport::Concern

  included do
    has_many :offer_owners, class_name: DataModules::Offer::OfferOwner, foreign_key: 'actor_id', dependent: :destroy
    has_many :offers, class_name: DataModules::Offer::Offer, through: :offer_owners

    def offers_to_hash
      offers.map { |o| o.to_hash }
    end

    # CLASS METHODS
    @d = self.default_attributes_for_json
    def self.default_attributes_for_json
      (@d + %i(count_offers)).freeze
    end

    @c = self.count_relation_whitelist_for_json
    def self.count_relation_whitelist_for_json
      (@c + %i(offers)).freeze
    end
  end

end
