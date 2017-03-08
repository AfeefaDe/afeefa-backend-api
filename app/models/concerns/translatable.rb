module Translatable

  extend ActiveSupport::Concern

  included do
    DEFAULT_LOCALE = 'de'

    after_save :update_or_create_translations
    after_destroy :destroy_translations

    def translation(locale: DEFAULT_LOCALE)
      client.get_translation(self, locale)
    end

    def self.translatable_attributes
      raise NotImplementedError "translatable attributes must be defined for class #{self.class}"
    end

    def client
      @client ||= PhraseAppClient.new
    end

    private

    def update_or_create_translations
      client.create_or_update_translation(self, 'de')
    end

    def destroy_translations
      client.delete_translation(self)
    end

  end

end
