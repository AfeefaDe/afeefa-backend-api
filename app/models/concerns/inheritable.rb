module Inheritable

  extend ActiveSupport::Concern

  INHERITABLE_ATTRIBUTES = %i(short_description contact_infos locations)

  included do
    validate :validate_inheritance
  end

  protected

  def validate_inheritance
    if inheritance.present? && (inheritance.map(&:to_sym) - INHERITABLE_ATTRIBUTES).any?
      errors.add(:inheritance)
    end
  end

end
