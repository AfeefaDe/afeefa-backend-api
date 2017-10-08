module Translatable

  extend ActiveSupport::Concern

  DEFAULT_LOCALE = 'de'.freeze
  TRANSLATABLE_LOCALES = ['ar', 'en', 'es', 'fa', 'fr', 'ku', 'pa', 'ps', 'ru', 'sq', 'sr', 'ti', 'tr', 'ur'].freeze
  PHRASEAPP_TRANSLATIONS_DIR = Rails.root.join('tmp', 'translations').freeze

  attr_accessor :force_translation_after_save

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
    after_destroy :destroy_translations,
      if: -> { (Settings.phraseapp.active || force_translation_after_save) }

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

  def update_or_create_translations
    unless respond_to?(:root_orga?) && root_orga?
      if translatable_attribute_changed? || force_translatable_attribute_update?
        json = build_json_for_phraseapp(only_changes: !force_translatable_attribute_update?)
        if json
          translation_file_name = "#{self.class.name.to_s.downcase}-#{id.to_s}-translation-#{DEFAULT_LOCALE}-"
          file = client.write_translation_upload_json(translation_file_name, json)
          client.push_locale_file(file, DEFAULT_LOCALE, tags: area)
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

  def build_json_for_phraseapp(only_changes: true)
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

  def destroy_translations
    client.delete_translation(self)
  end

end
