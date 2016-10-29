module Able

  extend ActiveSupport::Concern

  included do
    has_many :locations, as: :locatable
    has_many :annotations, as: :annotateable
    has_one :contact_info, as: :contactable
  end

end
