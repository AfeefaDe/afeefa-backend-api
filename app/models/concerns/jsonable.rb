module Jsonable

  extend ActiveSupport::Concern

  included do
    def to_hash
      {
        type: self.class.to_s.split('::').last.underscore.pluralize,
        id: id
      }
    end

    def as_json(options = nil)
      to_hash
    end
  end

end
