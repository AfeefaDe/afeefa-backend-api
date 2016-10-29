module Owner

  extend ActiveSupport::Concern

  included do
    # has_many :mailtemplates

    has_many :owner_thing_relations, as: :thingable
    has_many :events, through: :owner_thing_relations, source: :ownable, source_type: 'Event'
  end

end
