class ContactInfo < ApplicationRecord

  include Jsonable

  # CONSTANTS
  # PHONE = 'phone'
  # MAIL = 'mail'
  # WEB = 'web'
  # FACEBOOK = 'facebook'
  # TWITTER = 'twitter'
  # FREE_INFO ='free_info'
  # TYPES = [PHONE, MAIL, WEB,< FACEBOOK, TWITTER, FREE_INFO]

  # ATTRIBUTES AND ASSOCIATIONS
  belongs_to :contactable, polymorphic: true

  # VALIDATIONS
  # validates_presence_of :contactable

  # validations to prevent mysql errors
  validates :mail, length: { maximum: 255 }
  validates :phone, length: { maximum: 255 }
  validates :contact_person, length: { maximum: 255 }
  validates :web, length: { maximum: 1000 }
  validates :social_media, length: { maximum: 1000 }
  validates :spoken_languages, length: { maximum: 255 }

  # CLASS METHODS
  class << self
    def attribute_whitelist_for_json
      default_attributes_for_json.freeze
    end

    def default_attributes_for_json
      %i(contact_person mail phone web social_media opening_hours spoken_languages).freeze
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
    if mail.blank? && phone.blank?
      errors.add(:mail, 'Mail-Adresse oder Telefonnummer muss angegeben werden.')
      errors.add(:phone, 'Mail-Adresse oder Telefonnummer muss angegeben werden.')
    end
  end
end
