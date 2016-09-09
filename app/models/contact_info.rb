class ContactInfo < ApplicationRecord

  PHONE = 'phone'
  MAIL = 'mail'
  WEB = 'web'
  FACEBOOK = 'facebook'
  TWITTER = 'twitter'
  FREE_INFO ='free_info'
  TYPES = [ PHONE, MAIL, WEB, FACEBOOK, TWITTER, FREE_INFO ]

  belongs_to :contactable, polymorphic: true

end
