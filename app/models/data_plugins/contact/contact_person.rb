module DataPlugins::Contact
  class ContactPerson < ApplicationRecord

    self.table_name = 'contact_persons'

    include Jsonable

    # ASSOCIATIONS
    belongs_to :contact, class_name: ::DataPlugins::Contact::Contact

    # VALIDATIONS
    validates :mail, length: { maximum: 255 }
    validates :name, length: { maximum: 255 }
    validates :phone, length: { maximum: 255 }
    validates :role, length: { maximum: 255 }
    validate :ensure_mail_or_phone

    # CLASS METHODS
    class << self
      def attribute_whitelist_for_json
        default_attributes_for_json.freeze
      end

      def default_attributes_for_json
        %i(role mail name phone).freeze
      end
    end

    # override pluralization of contact_person
    def default_hash(type: nil)
      super(type: type.presence || 'contact_persons')
    end

    private

    def ensure_mail_or_phone
      if mail.blank? && phone.blank?
        errors.add('Kontakt', 'Email oder Telefonnummer muss angegeben werden.')
      end
    end
  end
end
