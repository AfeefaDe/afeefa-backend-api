module JsonableEntry

  extend ActiveSupport::Concern

  included do
    include Jsonable

    def to_hash(only_reference: false, details: false, with_relationships: false, with_short_relationships: false)
      if only_reference
        default_hash
      else
        hash = default_hash.merge(attributes: self.json_attributes(details: details))
        if with_short_relationships
          hash.merge(relationships: short_relationships_for_json)
        elsif with_relationships
          hash.merge(relationships: relationships_for_json)
        else
          hash
        end
      end
    end

    def json_attributes(details: false)
      hash = self.attributes.deep_symbolize_keys.
        slice(*self.class.whitelist_for_json(details: details)).
        merge(active: state == StateMachine::ACTIVE)
      hash.deep_merge(hash) { |_, _, v| v.to_s }
    end
  end

  module ClassMethods
    def whitelist_for_json(details: false)
      raise NotImplementedError, "whitelist_for_json must be defined for class #{self.class}"
    end
  end

  private

  def relationships_for_json
    raise NotImplementedError, "relationships_for_json must be defined for class #{self.class}"
  end

  def short_relationships_for_json
    {
      annotations: { data: annotations.map(&:to_hash) },
      category: { data: category.try(:to_hash) },
      sub_category: { data: sub_category.try(:to_hash) }
    }
  end

end
