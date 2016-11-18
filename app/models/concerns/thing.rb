module Thing

  extend ActiveSupport::Concern

  included do
    # INCLUDES
    include Able

    # ATTRIBUTES AND ASSOCIATIONS
    # not for now:
    # has_many :owner_thing_relations, as: :ownable
    # has_many :orgas, through: :owner_thing_relations, source: :thingable, source_type: 'Orga'
    belongs_to :orga
    # has_many :users, through: :owner_thing_relations, source: :thingable, source_type: 'User'

    # has_many :thing_category_relations, as: :catable
    # has_many :categories, through: :thing_category_relations
    #
    # has_many :thing_tag_relations
    # has_many :tags, through: :thing_tag_relations

    belongs_to :creator, class_name: 'User'

    # VALIDATIONS
    validates_presence_of :orga_id

    # HOOKS
    before_validation :set_orga_as_default, if: -> { orga.blank? }

    # INSTANCE METHODS
    private

    def set_orga_as_default
      self.orga = Orga.root_orga
    end
  end

end
