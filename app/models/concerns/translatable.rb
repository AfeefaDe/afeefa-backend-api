module Translatable

  extend ActiveSupport::Concern

  DEFAULT_LOCALE = 'de'.freeze
  TRANSLATABLE_LOCALES = ['ar', 'en', 'es', 'fa', 'fr', 'ku', 'pa', 'ps', 'ru', 'sq', 'sr', 'ti', 'tr', 'ur'].freeze
  AREAS = Area.order(:id).pluck(:title).freeze rescue ['dresden', 'leipzig', 'bautzen'].freeze

  # test flag, phraseapp generally inactive in testing, can be activated on a per instance basis
  attr_accessor :force_translation_after_save

  included do
    after_save :update_or_create_translations,
      if: -> { (Settings.phraseapp.active || force_translation_after_save) }

    after_save :create_fapi_cache_job, on: :update

    after_destroy :destroy_translations,
      if: -> { (Settings.phraseapp.active || force_translation_after_save) }

    def build_translation_key(attribute)
      "#{self.class.translation_key_type}.#{id}.#{attribute}"
    end

    def self.build_translation_key(id, attribute)
      "#{translation_key_type}.#{id}.#{attribute}"
    end

    def translation_key_type
      self.class.translation_key_type
    end
  end

  module ClassMethods
    def translatable_attributes
      raise NotImplementedError "translatable_attributes must be defined for class #{self.class}"
    end

    def translation_key_type
      name.to_s.split('::').last.downcase.underscore
    end
  end

  def client
    @@client ||= PhraseAppClient.new
  end

  def create_fapi_cache_job
    unless id_changed? # update
      if translatable_attribute_changed?
        # create translation cache job
        FapiCacheJob.new.update_entry_translation(self, DEFAULT_LOCALE)
      end
    end
  end

  def update_or_create_translations
    unless respond_to?(:root_orga?) && root_orga? # all entries except root orga
      if translatable_attribute_changed?
        json = create_json_for_translation_file
        if json
          translation_file_name = "#{translation_key_type}-#{id.to_s}-translation-#{DEFAULT_LOCALE}-"
          file = client.write_translation_upload_json(translation_file_name, json)
          if respond_to?(:area)
            client.upload_translation_file_for_locale(file, DEFAULT_LOCALE, tags: area)
          else
            client.upload_translation_file_for_locale(file, DEFAULT_LOCALE)
          end
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
        translation_key_type => {
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
