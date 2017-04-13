module Jsonable

  extend ActiveSupport::Concern

  included do
    def as_json(options = {})
      to_hash(
        only_reference: options[:only_reference] || false,
        details: options[:details] || false,
        with_short_relationships: options[:with_short_relationships]|| false,
        with_relationships: options[:with_relationships]|| false)
    end

    def default_hash
      @type ||= self.class.to_s.split('::').last.underscore.pluralize
      {
        type: @type,
        id: id.try(:to_s)
      }
    end

    def to_hash(only_reference: false, details: false, with_relationships: false, with_short_relationships: false)
      if only_reference
        default_hash
      else
        hash = default_hash.
          merge(attributes: self.json_attributes(details: details).
            merge(to_hash_additionals))
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
      hash = self.attributes.deep_symbolize_keys.slice(*self.class.whitelist_for_json(details: details))
      hash.deep_merge(hash) { |_, _, v| v.to_s }
    end

    def to_hash_additionals
      {}
    end

    private

    def relationships_for_json
      raise NotImplementedError, "relationships_for_json must be defined for class #{self.class}"
    end

    def short_relationships_for_json
      raise NotImplementedError, "short_relationships_for_json must be defined for class #{self.class}"
    end

  end

  module ClassMethods
    def whitelist_for_json(details: false)
      # raise NotImplementedError, "whitelist_for_json must be defined for class #{self.class}"
      whitelist = %i(title)
      if details
        whitelist += %i(created_at updated_at)
      end
      whitelist
    end
  end

end
