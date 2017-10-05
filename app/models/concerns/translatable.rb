module Translatable

  extend ActiveSupport::Concern

  DEFAULT_LOCALE = 'de'.freeze
  PHRASEAPP_TRANSLATIONS_DIR = Rails.root.join('tmp', 'translations').freeze

  included do
    scope :empty_translatable_attributes, ->() {
      conditions =
        translatable_attributes.map do |attribute|
          "#{attribute} IS NULL OR #{attribute} = ''"
        end.join(' OR ')
      where(conditions)
    }

    after_save :update_or_create_translations,
      if: -> { (Settings.phraseapp.active rescue false) }
    after_destroy :destroy_translations,
      if: -> { (Settings.phraseapp.active rescue false) }

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
        # client.create_or_update_translation(self, 'de')

        # use json file upload
        FileUtils.mkdir_p(PHRASEAPP_TRANSLATIONS_DIR)
        phraseapp_translations_file_path =
          File.join(PHRASEAPP_TRANSLATIONS_DIR,
            "translation-new-#{DEFAULT_LOCALE}-#{self.class.name.to_s}-#{id.to_s}.json")
        write_json_file_for_phraseapp(phraseapp_translations_file_path,
          only_changes: !force_translatable_attribute_update?, skip_empty_content: true)
        push_json_file_to_phraseapp(phraseapp_translations_file_path, tags: area)
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
    {
      self.class.name.to_s.underscore => {
        id.to_s => attribute_translations
      }
    }
  end

  def write_json_file_for_phraseapp(phraseapp_translations_file_path, only_changes: true, skip_empty_content: false)
    file = File.new(phraseapp_translations_file_path, 'w:UTF-8')
    file.write(
      JSON.pretty_generate(
        build_json_for_phraseapp(only_changes: only_changes, skip_empty_content: skip_empty_content)))
    file.close
  end

  def push_json_file_to_phraseapp(phraseapp_translations_file_path, tags: nil)
    client.push_locale_file(phraseapp_translations_file_path,
      client.locale_id(DEFAULT_LOCALE),
      tags: tags
    )
  end

  def destroy_translations
    client.delete_translation(self, dry_run: false)
  end

end
