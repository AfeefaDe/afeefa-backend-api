module DataModules::Offer::Concerns::HasOffers

  extend ActiveSupport::Concern

  included do
    has_many :owner_offers, class_name: DataModules::Offer::OwnerOffer, foreign_key: 'actor_id'
    has_many :offers, class_name: DataModules::Offer::Offer, through: :owner_offers

    def offers_to_hash
      offers.map { |o| o.to_hash(attributes: o.class.default_attributes_for_json, relationships: nil) }
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
