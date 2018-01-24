module DataPlugins::Contact::Concerns::HasContacts

  extend ActiveSupport::Concern

  included do
    # ASSOCIATIONS
    has_many :contacts, class_name: ::DataPlugins::Contact::Contact, foreign_key: :owner_id

    has_one :main_contact, -> { ::DataPlugins::Contact::Contact.main.limit(1) },
      class_name: ::DataPlugins::Contact::Contact, foreign_key: :owner_id
    has_many :sub_contacts, -> { ::DataPlugins::Contact::Contact.sub },
      class_name: ::DataPlugins::Contact::Contact, foreign_key: :owner_id

    has_many :contact_persons, class_name: ::DataPlugins::Contact::ContactPerson, through: :contacts
  end

end
