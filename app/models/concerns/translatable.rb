module Translatable

  extend ActiveSupport::Concern

  included do
    def translatable_attributes
      raise NotImplementedError "translatable attributes must be defined for class #{self.class}"
    end
  end

end
