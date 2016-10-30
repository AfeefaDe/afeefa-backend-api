module Able

  extend ActiveSupport::Concern

  included do
    include StateMachine

    has_many :locations, as: :locatable
    has_many :annotations, as: :annotatable
    has_many :contact_infos, as: :contactable

    scope :annotateds, -> { includes(:annotations).references(:annotations).where(annotations: { id: nil }) }

  end

end
