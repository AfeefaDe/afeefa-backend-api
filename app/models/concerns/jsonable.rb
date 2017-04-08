module Jsonable

  extend ActiveSupport::Concern

  included do
    def default_hash
      @@type ||= self.class.to_s.split('::').last.underscore.pluralize
      {
        type: @@type,
        id: id
      }
    end

    def to_hash(only_reference: false)
      default_hash
    end

    def as_json(options = nil)
      to_hash
    end
  end

end
