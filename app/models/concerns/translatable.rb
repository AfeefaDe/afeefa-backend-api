module Translatable

  extend ActiveSupport::Concern

  included do
    DEFAULT_LOCALE = 'de'

    after_save :update_or_create_translations,
      unless: -> { Settings.phraseapp.active || false && skip_phraseapp_translations? }
    after_destroy :destroy_translations,
      unless: -> { Settings.phraseapp.active || false }

    class << self
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

    def skip_phraseapp_translations!
      @skip_phraseapp_translations = true
    end

    def do_not_skip_phraseapp_translations!
      @skip_phraseapp_translations = false
    end

    def skip_phraseapp_translations?
      @skip_phraseapp_translations || false
    end

    private

    def update_or_create_translations
      unless respond_to?(:root_orga?) && root_orga?
        client.create_or_update_translation(self, 'de')
      end
    end

    def destroy_translations
      client.delete_translation(self)
    end

  end

end
