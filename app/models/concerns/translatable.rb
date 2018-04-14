module Translatable

  extend ActiveSupport::Concern

  DEFAULT_LOCALE = 'de'.freeze
  TRANSLATABLE_LOCALES = ['ar', 'en', 'es', 'fa', 'fr', 'ku', 'pa', 'ps', 'ru', 'sq', 'sr', 'ti', 'tr', 'ur'].freeze
  AREAS = Area.order(:id).pluck(:title).freeze rescue ['dresden', 'leipzig', 'bautzen'].freeze

  # test flag, phraseapp generally inactive in testing, can be activated on a per instance basis
  attr_accessor :force_translation_after_save, :force_sync_fapi_after_save

  included do
    scope :empty_translatable_attributes, ->() {
      conditions =
        translatable_attributes.map do |attribute|
          "#{attribute} IS NULL OR #{attribute} = ''"
        end.join(' OR ')
      where(conditions)
    }

    after_save :update_or_create_translations,
      if: -> { (Settings.phraseapp.active || force_translation_after_save) }

    after_save :set_had_changes,
      if: -> { (Settings.afeefa.fapi_sync_active || force_sync_fapi_after_save) }
    after_commit :sync_fapi_after_change, on: [:create, :update],
      if: -> { (Settings.afeefa.fapi_sync_active || force_sync_fapi_after_save) }

    after_destroy :destroy_translations,
      if: -> { (Settings.phraseapp.active || force_translation_after_save) }
    after_destroy :sync_fapi_after_destroy,
      if: -> { (Settings.afeefa.fapi_sync_active || force_sync_fapi_after_save) }

    def build_translation_key(attribute)
      "#{self.class.name.underscore}.#{id}.#{attribute}"
    end

    def self.build_translation_key(id, attribute)
      "#{name.underscore}.#{id}.#{attribute}"
    end

    def force_translatable_attribute_update!
      @force_translatable_attribute_update = true
    end

    def do_not_force_translatable_attribute_update!
      @force_translatable_attribute_update = false
    end

    def force_translatable_attribute_update?
      @force_translatable_attribute_update || false
    end
  end

  module ClassMethods
    def translatable_attributes
      raise NotImplementedError "translatable_attributes must be defined for class #{self.class}"
    end
  end

  def client
    @@client ||= PhraseAppClient.new
  end

  def fapi_client
    @@fapi_client ||= FapiClient.new
  end

  def update_or_create_translations
    unless respond_to?(:root_orga?) && root_orga? # all entries except root orga
      if translatable_attribute_changed? || force_translatable_attribute_update?
        json = create_json_for_translation_file(only_changes: !force_translatable_attribute_update?)
        if json
          translation_file_name = "#{self.class.name.to_s.downcase}-#{id.to_s}-translation-#{DEFAULT_LOCALE}-"
          file = client.write_translation_upload_json(translation_file_name, json)
          client.upload_translation_file_for_locale(file, DEFAULT_LOCALE, tags: area)
        else
          Rails.logger.debug(
            'skip phraseapp save hook because no nonempty translatable attributes present')
        end
      else
        Rails.logger.debug(
          'skip phraseapp save hook because no translatable attribute was changed')
      end
    end
  end

  def set_had_changes
    # jsonapi calls two times save where the second call won't have changes anymore
    # hence we only allow setting changes to true :-)
    @had_changes = true if changed?
  end

  def sync_fapi_after_change
    if @had_changes
      entries_to_update = get_entries_to_update_in_frontend
      if entries_to_update.any?
        entries_to_update.each do |entry|
          fapi_client.entry_updated(entry)
        end
      end
      @had_changes = false
    end
  end

  def sync_fapi_after_destroy
    fapi_client.entry_deleted(self)
  end

  def create_json_for_translation_file(only_changes: true)
    attribute_translations = {}
    attributes_to_handle = self.class.translatable_attributes

    if only_changes
      attributes_to_handle.select! { |attribute| attribute.to_s.in?(changes.keys.map(&:to_s)) }
    end

    attributes_to_handle.each do |attribute|
      next if send(attribute).blank?
      attribute_translations[attribute.to_s] = send(attribute).presence
    end

    if !attribute_translations.empty?
      return {
        self.class.name.to_s.underscore => {
          id.to_s => attribute_translations
        }
      }
    end

    return nil
  end

  private

  def translatable_attribute_changed?
    changed? &&
      self.class.translatable_attributes.
        any? { |attribute| attribute.to_s.in?(changes.keys.map(&:to_s)) }
  end

  def get_entries_to_update_in_frontend
    changed_entries = [self]

    return changed_entries if !@had_changes

    parent_orga_changes = nil

    # parent orga, currently not necessary since entries are fully indepentent in fapi
    # when activating, please keep track of actual changes in after_save hook 'set_had_changes'

    # if changes.key?('parent_orga_id') # orga.orga
    #   parent_orga_changes = changes['parent_orga_id']
    # elsif changes.key?('orga_id') # event.orga
    #   parent_orga_changes = changes['orga_id']
    # end

    # if parent_orga_changes
    #   old_orga = Orga.find_by(id: parent_orga_changes[0])
    #   if old_orga && !old_orga.root_orga?
    #     changed_entries << old_orga
    #   end

    #   new_orga = Orga.find_by(id: parent_orga_changes[1])
    #   if new_orga && !new_orga.root_orga?
    #     changed_entries << new_orga
    #   end
    # end

    # child orgas or events with inheritance

    if is_a?(Orga)
      sub_orgas.each do |suborga|
        if suborga.inheritance.present?
          changed_entries << suborga
        end
      end

      Event.where(orga_id: id).each do |event|
        if event.inheritance.present?
          changed_entries << event
        end
      end
    end
    changed_entries
  end

  def destroy_translations
    client.delete_translation(self)
  end

end
