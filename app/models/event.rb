require 'errors'

class Event < ApplicationRecord

  include Thing
  include JsonableEntry

  acts_as_tree(dependent: :restrict_with_exception)
  alias_method :sub_events, :children
  alias_method :parent_event, :parent
  alias_method :parent_event=, :parent=
  alias_method :sub_events=, :children=

  validates :date_start, presence: true

  class << self
    def whitelist_for_json(details: false)
      whitelist =
        %i(title created_at updated_at state_changed_at
          date_start date_end time_start time_end)
      if details
        whitelist +=
          %i(description media_url media_type support_wanted for_children certified_sfr
            public_speaker location_type legacy_entry_id migrated_from_neos)
      end
      whitelist
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

  def relationships_for_json
    short_relationships_for_json.merge(
      locations: { data: locations.map { |orga| orga.to_hash(only_reference: true) } },
      contact_infos: { data: contact_infos.map { |orga| orga.to_hash(only_reference: true) } },
      orga: { data: orga.try(:to_hash, only_reference: true) }
    )
  end

end
