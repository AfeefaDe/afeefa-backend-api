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

  scope :upcoming, -> {
    now = Time.now.beginning_of_day
    # date_start > today 00:00
    # date_end > today 00:00
    where.not(date_start: [nil, '']).
      where('date_start >= ?', now).
      or(where('date_start = ?', now)).
      or(where('date_end >= ?', now))
  }

  scope :past, -> {
    now = Time.now.beginning_of_day
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
          date_start date_end upcoming
          has_time_start has_time_end active inheritance).freeze
    end

    def relation_whitelist_for_json
      (default_relations_for_json + %i(locations contact_infos orga parent_event sub_events)).freeze
    end

    def default_relations_for_json
      %i(annotations category sub_category creator last_editor).freeze
    end
  end

  def upcoming?
    if persisted?
      id.in?(Event.upcoming.pluck(:id))
    else
      now = Time.now.beginning_of_day
      # date_start > today 00:00
      # date_end > today 00:00
      date_start.present? && date_start >= now ||
        date_start == now ||
        date_end >= now
    end
  end
  alias_method :upcoming, :upcoming?

  def past?
    if persisted?
      id.in?(Event.past.pluck(:id))
    else
      now = Time.now.beginning_of_day
      # kein date_end und date_start < today 00:00
      # hat date_end und date_end < today 00:00
      date_end.blank? && date_start.present? && date_start < now ||
        date_end.present? == date_end < now ||
        date_start.blank?
    end
  end
  alias_method :past, :past?

  def orga_to_hash
    if orga && !orga.root_orga?
      orga.to_hash
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
