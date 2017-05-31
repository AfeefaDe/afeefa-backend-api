require 'errors'

class Event < ApplicationRecord

  include Thing
  include Jsonable

  acts_as_tree(dependent: :restrict_with_exception)
  alias_method :sub_events, :children
  alias_method :parent_event, :parent
  alias_method :parent_event=, :parent=
  alias_method :sub_events=, :children=

  validates :date_start, presence: true, unless: :skip_all_validations?

  class << self
    def attribute_whitelist_for_json
      (default_attributes_for_json +
        %i(description short_description media_url media_type support_wanted for_children tags certified_sfr
            public_speaker location_type legacy_entry_id)).freeze
    end

    def default_attributes_for_json
      %i(title created_at updated_at state_changed_at
          date_start date_end has_time_start has_time_end active inheritance).freeze
    end

    def relation_whitelist_for_json
      (default_relations_for_json + %i(locations contact_infos orga parent_event sub_events)).freeze
    end

    def default_relations_for_json
      %i(annotations category sub_category).freeze
    end
  end

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

  def has_time_start
    time_start?
  end

  def has_time_end
    time_end?
  end

end
