module Able

  extend ActiveSupport::Concern

  included do
    # INCLUDES
    include StateMachine

    auto_strip_attributes :title, :description

    # CONSTANTS
    SUB_CATEGORIES =
      # mapping for subcategories given by old frontend
      {
        general: [
          { name: 'wifi', id: '0-1' },
          { name: 'jewish', id: '0-2' },
          { name: 'christian', id: '0-3' },
          { name: 'islam', id: '0-4' },
          { name: 'religious-other', id: '0-5' },
          { name: 'shop', id: '0-6' },
          { name: 'nature', id: '0-7' },
          { name: 'authority', id: '0-8' },
          { name: 'hospital', id: '0-9' },
          { name: 'police', id: '0-10' },
          { name: 'public-transport', id: '0-11' }
        ],
        language: [
          { name: 'german-course', id: '1-1' },
          { name: 'interpreter', id: '1-2' },
          { name: 'learning-place', id: '1-3' },
          { name: 'tandem', id: '1-4' }
        ],
        medic: [
          { name: 'medical-counselling', id: '2-1' },
          { name: 'medical-care', id: '2-2' },
          { name: 'psychological-counselling', id: '2-3' }
        ],
        jobs: [
          { name: 'job-counselling', id: '3-1' },
          { name: 'education-counselling', id: '3-2' },
          { name: 'political-education', id: '3-3' },
          { name: 'education-sponsorship', id: '3-4' },
          { name: 'library', id: '3-5' }
        ],
        consultation: [
          { name: 'asylum-counselling', id: '4-1' },
          { name: 'legal-advice', id: '4-2' },
          { name: 'social-counselling', id: '4-3' },
          { name: 'family-counselling', id: '4-4' },
          { name: 'women-counselling', id: '4-5' },
          { name: 'volunteer-coordination', id: '4-6' }
        ],
        leisure: [
          { name: 'youth-club', id: '5-1' },
          { name: 'sports', id: '5-2' },
          { name: 'museum', id: '5-3' },
          { name: 'music', id: '5-4' },
          { name: 'stage', id: '5-5' },
          { name: 'craft-art', id: '5-6' },
          { name: 'gardening', id: '5-7' },
          { name: 'cooking', id: '5-8' },
          { name: 'festival', id: '5-9' },
          { name: 'lecture', id: '5-10' }
        ],
        community: [
          { name: 'welcome-network', id: '6-1' },
          { name: 'meeting-place', id: '6-2' },
          { name: 'childcare', id: '6-3' },
          { name: 'workshop', id: '6-4' },
          { name: 'sponsorship', id: '6-5' },
          { name: 'lgbt', id: '6-6' },
          { name: 'housing-project', id: '6-7' }
        ],
        donation: [
          { name: 'food', id: '7-1' },
          { name: 'clothes', id: '7-2' },
          { name: 'furniture', id: '7-3' }
        ]
      }

    # ATTRIBUTES AND ASSOCIATIONS
    has_many :locations, as: :locatable
    has_many :contact_infos, as: :contactable

    has_many :annotation_able_relations, as: :entry
    has_many :annotations, through: :annotation_able_relations

    belongs_to :category, optional: true
    belongs_to :sub_category, class_name: 'Category', optional: true

    scope :annotated, -> { joins(:annotations) }
    scope :unannotated, -> { includes(:annotations).references(:annotations).where(annotations: { id: nil }) }

    # VALIDATIONS
    validates :contact_infos, presence: true, on: :update
    validates :category, presence: true, on: :update

    validates :title, presence: true, length: { maximum: 150 }
    validates_uniqueness_of :title
    validates :description, presence: true, length: { maximum: 350 }

    # HOOKS
    before_destroy :deny_destroy_if_associated_objects_present, prepend: true

  end

end
