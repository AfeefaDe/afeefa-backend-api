require 'errors'

class Event < ApplicationRecord

  # INCLUDES
  include Thing

  # ATTRIBUTES AND ASSOCIATIONS
  acts_as_tree(dependent: :restrict_with_exception)
  alias_method :sub_events, :children
  alias_method :parent_event, :parent
  alias_method :parent_event=, :parent=
  alias_method :sub_events=, :children=

  # VALIDATIONS
  validates :date_start, presence: true

  # HOOKS

  # SCOPES

  # CLASS METHODS

  # INSTANCE METHODS
  private

  def deny_destroy_if_associated_objects_present
    errors.clear

    if sub_events.any?
      errors.add(:sub_events, :not_blank)
    end

    errors.full_messages.each do |message|
      raise CustomDeleteRestrictionError, message
    end
  end

end
