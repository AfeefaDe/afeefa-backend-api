require 'errors'

class Event < ApplicationRecord

  include Thing
  include Jsonable

  acts_as_tree(dependent: :restrict_with_exception)
  alias_method :sub_events, :children
  alias_method :parent_event, :parent
  alias_method :parent_event=, :parent=
  alias_method :sub_events=, :children=

  validates :date_start, presence: true

  def to_hash(only_reference: false, details: false)
    if only_reference
      default_hash
    else
      whitelist =
        %w(title created_at updated_at state_changed_at
          date_start date_end time_start time_end)
      if details
        whitelist +=
          %w(description media_url media_type support_wanted for_children certified_sfr
            public_speaker location_type legacy_entry_id migrated_from_neos)
      end
      attributes_hash =
        self.attributes.slice(whitelist).merge(active: state == ACTIVE)
      default_hash.merge(
        # links: {
        #   self: (Rails.application.routes.url_helpers.api_v1_orga_url(self) rescue 'not available')
        # },
        attributes: attributes_hash,
        relationships: {
          annotations: {
            # links: { related: '' },
            data: annotations.map(&:to_hash)
          },
          locations: { data: locations.map(&:to_hash) },
          contact_infos: { data: contact_infos.map(&:to_hash) },
          category: { data: category.try(:to_hash) },
          sub_category: { data: sub_category.try(:to_hash) },
          orga: { data: orga.try(:to_hash, only_reference: true) },
        }
      )
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

end
