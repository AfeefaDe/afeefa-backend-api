module Thing

  extend ActiveSupport::Concern

  included do
    NEW = 'new'
    EDIT_REQUEST = 'edit_request'
    DELETE_REQUEST = 'delete_request'

    STATES = [ NEW, EDIT_REQUEST, DELETE_REQUEST ]

    has_many :owner_thing_relations, as: :ownable
    has_many :users, through: :owner_thing_relations, source: :thingable, source_type: 'User'
    has_many :orgas, through: :owner_thing_relations, source: :thingable, source_type: 'Orga'

    has_many :thing_category_relations, as: :catable
    has_many :categories, through: :thing_category_relations

    has_many :thing_tag_relations
    has_many :tags, through: :thing_tag_relations

    has_many :locations, as: :locatable

    belongs_to :creator, class_name: 'User'
  end

end
