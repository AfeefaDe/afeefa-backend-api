module Jsonable

  extend ActiveSupport::Concern

  included do
    def default_hash
      @type ||= self.class.to_s.split('::').last.underscore.pluralize
      {
        type: @type,
        id: id.to_s
      }
    end

    def to_hash(only_reference: false, details: false, with_relationships: false)
      default_hash
    end

    def as_json(options = {})
      to_hash(
        only_reference: options[:only_reference] || false,
        details: options[:details] || false,
        with_relationships: options[:with_relationships]|| false)
    end
  end

end
