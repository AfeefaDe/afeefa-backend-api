module Able

  extend ActiveSupport::Concern

  included do
    # INCLUDES
    include StateMachine

    # CONSTANTS
    CATEGORIES = ['jobs', 'donation', 'leisure', 'language', 'community', 'general', 'medic', 'consultation']

    # ATTRIBUTES AND ASSOCIATIONS
    has_many :locations, as: :locatable
    has_many :annotations, as: :annotatable
    has_many :contact_infos, as: :contactable

    scope :annotated, -> { joins(:annotations) }
    scope :unannotated, -> { includes(:annotations).references(:annotations).where(annotations: { id: nil }) }

    # VALIDATIONS
    validates :title, presence: true, length: { maximum: 150 }
    validates_uniqueness_of :title
    validates :description, presence: true, length: { maximum: 150 }
    validates :category, inclusion: { in: CATEGORIES }
  end

end
