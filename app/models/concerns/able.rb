module Able

  extend ActiveSupport::Concern

  included do
    # INCLUDES
    include StateMachine

    # ATTRIBUTES AND ASSOCIATIONS
    has_many :locations, as: :locatable
    has_many :annotations, as: :annotatable
    has_many :contact_infos, as: :contactable

    scope :annotated, -> { joins(:annotations) }
    scope :unannotated, -> { includes(:annotations).references(:annotations).where(annotations: { id: nil }) }
  end

end
