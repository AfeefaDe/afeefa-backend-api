class AnnotationCategory < ApplicationRecord

  include Jsonable

  has_many :annotations

  def entries
    Annotation.by_area(Current.user.area).group_by_entry.
      where(annotation_category_id: id)
  end

  # CLASS METHODS
  class << self
    def attribute_whitelist_for_json
      default_attributes_for_json
    end

    def default_attributes_for_json
      %i(title generated_by_system count_entries).freeze
    end

    def count_relation_whitelist_for_json
      %i(entries).freeze
    end
  end

end
