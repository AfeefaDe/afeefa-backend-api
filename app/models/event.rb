require 'errors'

class Event < ApplicationRecord

  # to get rid of invalid encoding on facebook import:
  # serialize :title
  # serialize :description
  # serialize :short_description

  include Thing
  include Jsonable

  acts_as_tree(foreign_key: :parent_event_id)
  alias_method :sub_events, :children
  alias_method :parent_event, :parent
  alias_method :parent_event=, :parent=
  alias_method :sub_events=, :children=
  alias_attribute :parent_id, :parent_event_id

  has_many :event_hosts, class_name: EventHost, dependent: :destroy
  has_many :hosts, through: :event_hosts, source: :actor

  # VALIDATIONS
  validates :date_start, presence: true

  # validations to prevent mysql errors
  validates :public_speaker, length: { maximum: 255 }

  # HOOKS
  before_validation :unset_inheritance, if: -> { orga.root_orga? && !skip_unset_inheritance? }

  scope :all_for_ids, -> (ids, includes = default_includes) {
    includes(includes).
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

    def lazy_attributes_for_json
      %i(title active created_at updated_at
        date_start date_end has_time_start has_time_end).freeze
    end

    def default_attributes_for_json
      (lazy_attributes_for_json + %i(state_changed_at)).freeze
    end

    def relation_whitelist_for_json
      (default_relations_for_json + %i(contacts)).freeze
    end

    def lazy_relations_for_json
      %i(facet_items navigation_items).freeze
    end

    def default_relations_for_json
      (lazy_relations_for_json + %i(hosts annotations creator last_editor)).freeze
    end

    def lazy_includes
      [
        :facet_items,
        :navigation_items
      ]
    end

    def default_includes
      lazy_includes + [
        :hosts,
        :creator,
        :last_editor,
        :annotations
      ]
    end
  end

  def link_host(actor_id)
    host = Orga.find(actor_id)
    unless host.area == self.area
      raise 'Host is in wrong area'
    end
    EventHost.create(
      actor_id: actor_id,
      event: self
    )
  end

  # TODO hosts are part of the list resource as well as the item resource
  # but we want to include more host details on the item resource
  # hence, there is a patch of this method in events_controller#show
  def hosts_to_hash
    hosts.map { |h| h.to_hash(attributes: ['title'], relationships: nil) }
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
