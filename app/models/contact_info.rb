class ContactInfo < ApplicationRecord

  include Jsonable

  # CONSTANTS
  # PHONE = 'phone'
  # MAIL = 'mail'
  # WEB = 'web'
  # FACEBOOK = 'facebook'
  # TWITTER = 'twitter'
  # FREE_INFO ='free_info'
  # TYPES = [PHONE, MAIL, WEB, FACEBOOK, TWITTER, FREE_INFO]

  # ATTRIBUTES AND ASSOCIATIONS
  belongs_to :contactable, polymorphic: true

  # VALIDATIONS
  # validates_presence_of :contactable
  # validate :ensure_mail_or_phone

  private

  def ensure_mail_or_phone
    if mail.blank? && phone.blank?
      errors.add(:mail, 'Mail-Adresse oder Telefonnummer muss angegeben werden.')
      errors.add(:phone, 'Mail-Adresse oder Telefonnummer muss angegeben werden.')
    end
  end
end
