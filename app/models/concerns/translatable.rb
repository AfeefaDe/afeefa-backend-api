module Translatable

  extend ActiveSupport::Concern

  DEFAULT_LOCALE = 'de'.freeze
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

  def translation(locale: DEFAULT_LOCALE)
    client.get_translation(self, locale)
  end

  def client
    @@client ||= PhraseAppClient.new
  end

  def update_or_create_translations
    unless respond_to?(:root_orga?) && root_orga?
      if translatable_attribute_changed? || force_translatable_attribute_update?
        json = build_json_for_phraseapp(only_changes: !force_translatable_attribute_update?, skip_empty_content: true)
        if json
          translation_file_name = "#{self.class.name.to_s.downcase}-#{id.to_s}-translation-#{DEFAULT_LOCALE}-"
          file = write_json_file_for_phraseapp(translation_file_name, json)
          push_json_file_to_phraseapp(file, tags: area)
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

  private

  def translatable_attribute_changed?
    changed? &&
      self.class.translatable_attributes.
        any? { |attribute| attribute.to_s.in?(changes.keys.map(&:to_s)) }
  end

  def build_json_for_phraseapp(only_changes: true, skip_empty_content: false)
    attribute_translations = {}
    attributes_to_handle = self.class.translatable_attributes
    if only_changes
      attributes_to_handle.
        select! { |attribute| attribute.to_s.in?(changes.keys.map(&:to_s)) }
    end
    attributes_to_handle.each do |attribute|
      next if skip_empty_content && send(attribute).blank?
      # set one space as default because phraseapp api does not
      # import empty translations via json file upload
      attribute_translations[attribute.to_s] =
        send(attribute).presence || ' '
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

  def write_json_file_for_phraseapp(translation_file_name, json)
    file = Tempfile.new([translation_file_name, '.json'], encoding: 'UTF-8')
    file.write(JSON.pretty_generate(json))
    file.close
    file
  end

  def push_json_file_to_phraseapp(file, tags: nil)
    client.push_locale_file(file,
      client.locale_id(DEFAULT_LOCALE),
      tags: tags
    )
  end

  def destroy_translations
    client.delete_translation(self, dry_run: false)
  end

end
