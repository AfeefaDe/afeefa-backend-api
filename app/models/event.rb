require 'errors'

class Event < ApplicationRecord

  include Thing
  include Jsonable

  acts_as_tree(dependent: :restrict_with_exception, foreign_key: :parent_event_id)
  alias_method :sub_events, :children
  alias_method :parent_event, :parent
  alias_method :parent_event=, :parent=
  alias_method :sub_events=, :children=
  alias_attribute :parent_id, :parent_event_id

  # VALIDATIONS
  validates :date_start, presence: true

  # validations to prevent mysql errors
  validates :public_speaker, length: { maximum: 255 }

  # HOOKS
  before_validation :unset_inheritance, if: -> { orga.root_orga? && !skip_unset_inheritance? }

  scope :all_for_ids, -> (ids) {
    includes(Event.default_includes).
    where(id: ids)
  }

  scope :upcoming, -> {
    now = Time.now.in_time_zone(Time.zone).beginning_of_day
    # date_start > today 00:00
    # date_end > today 00:00
    where.not(date_start: [nil, '']).
      where('date_start >= ?', now).
      or(where('date_start = ?', now)).
      or(where('date_end >= ?', now))
  }

  scope :past, -> {
    now = Time.now.in_time_zone(Time.zone).beginning_of_day
    # kein date_end und date_start < today 00:00
    # hat date_end und date_end < today 00:00
    where(date_end: [nil, '']).
      where.not(date_start: [nil, '']).
      where('date_start < ?', now).

      or(where.not(date_end: [nil, '']).
        where('date_end < ?', now)).

      or(where(date_start: [nil, ''])) # legacy events without date start
  }

  class << self
    def attribute_whitelist_for_json
      (default_attributes_for_json +
        %i(description short_description media_url media_type
            support_wanted support_wanted_detail
            tags certified_sfr
            public_speaker location_type legacy_entry_id facebook_id)).freeze
    end

    def default_attributes_for_json
      %i(title created_at updated_at state_changed_at
          date_start date_end
          has_time_start has_time_end active inheritance).freeze
    end

    def relation_whitelist_for_json
      (default_relations_for_json + %i(contacts)).freeze
    end

    def default_relations_for_json
      %i(orga annotations category sub_category facet_items creator last_editor).freeze
    end

    def default_includes
      [
        :category,
        :sub_category,
        :facet_items,
        :creator,
        :last_editor,
        :annotations,
        {orga: Orga.default_includes}
      ]
    end
  end

  def orga_to_hash
    if orga && !orga.root_orga?
      orga.to_hash
    end
  end

  def contacts_to_hash
    contacts.map { |c| c.to_hash(attributes: c.class.default_attributes_for_json) }
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

  # INCLUDE NEW CODE FROM ACTOR
  include DataPlugins::Contact::Concerns::HasContacts
  include DataPlugins::Location::Concerns::HasLocations
  include DataPlugins::Facet::Concerns::HasFacetItems
  include DataModules::FeNavigation::Concerns::HasFeNavigationItems

end
