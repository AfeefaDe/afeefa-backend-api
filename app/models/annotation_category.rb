class AnnotationCategory < ApplicationRecord

  include Jsonable

  has_many :annotations
  has_many :events, through: :annotations, source: :entry, source_type: 'Event'
  has_many :orgas, through: :annotations, source: :entry, source_type: 'Orga'

  # CLASS METHODS
  class << self
    def attribute_whitelist_for_json
      default_attributes_for_json
    end

    def default_attributes_for_json
      %i(title).freeze
    end
  end

end
