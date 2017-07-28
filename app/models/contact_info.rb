class ContactInfo < ApplicationRecord

  include Jsonable

  # CONSTANTS
  # PHONE = 'phone'
  # FAX = 'fax'
  # MAIL = 'mail'
  # WEB = 'web'
  # FACEBOOK = 'facebook'
  # TWITTER = 'twitter'
  # FREE_INFO ='free_info'
  # TYPES = [PHONE, FAX, MAIL, WEB,< FACEBOOK, TWITTER, FREE_INFO]

  # ATTRIBUTES AND ASSOCIATIONS
  belongs_to :contactable, polymorphic: true

  # VALIDATIONS
  # validates_presence_of :contactable
  # validate :ensure_mail_or_phone_or_fax

  # CLASS METHODS
  class << self
    def attribute_whitelist_for_json
      default_attributes_for_json.freeze
    end

    def default_attributes_for_json
      %i(contact_person mail phone fax web social_media opening_hours spoken_languages).freeze
    end

    def relation_whitelist_for_json
      default_relations_for_json.freeze
    end

    def default_relations_for_json
      %i(contactable).freeze
    end
  end

  private

  def ensure_mail_or_phone
    if mail.blank? && phone.blank? && fax.blank?
      errors.add(:mail, 'Mail-Adresse, Telefonnummer oder Fax muss angegeben werden.')
      errors.add(:phone, 'Mail-Adresse, Telefonnummer oder Fax muss angegeben werden.')
      errors.add(:fax, 'Mail-Adresse, Telefonnummer oder Fax muss angegeben werden.')
    end
  end
end
