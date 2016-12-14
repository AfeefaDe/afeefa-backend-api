module Able

  extend ActiveSupport::Concern

  included do
    # INCLUDES
    include StateMachine

    # ATTRIBUTES AND ASSOCIATIONS
    has_many :locations, as: :locatable
    has_many :annotations, as: :annotatable
    has_many :contact_infos, as: :contactable
    belongs_to :category
    belongs_to :sub_category, class_name: 'Category'

    scope :annotated, -> { joins(:annotations) }
    scope :unannotated, -> { includes(:annotations).references(:annotations).where(annotations: { id: nil }) }

    # VALIDATIONS
    validates :locations, presence: true, on: :update
    validates :contact_infos, presence: true, on: :update

    validates :title, presence: true, length: { maximum: 150 }
    validates_uniqueness_of :title
    validates :description, presence: true, length: { maximum: 150 }
    validates :category, presence: true
  end

end
