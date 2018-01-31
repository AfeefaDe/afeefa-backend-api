module DataPlugins::Contact::Concerns::HasContacts

  extend ActiveSupport::Concern

  included do
    # ASSOCIATIONS
    has_many :contacts, class_name: DataPlugins::Contact::Contact, as: :owner

    has_one :main_contact, -> { DataPlugins::Contact::Contact.main.limit(1) },
      class_name: DataPlugins::Contact::Contact, as: :owner

    has_many :sub_contacts, -> { DataPlugins::Contact::Contact.sub },
      class_name: DataPlugins::Contact::Contact, as: :owner

    has_many :contact_persons, class_name: DataPlugins::Contact::ContactPerson, through: :contacts
  end

  def create_contact(params)
    contact = nil
    contact_persons = []
    ActiveRecord::Base.transaction do
      contact_params = params.permit(*self.class.contact_params)

      unless contact_params[:location_id]
        location =
          DataPlugins::Location::Location.
            # We assume that our own class knows about location_params, it has to include HasLocations
            create(params.permit(*self.class.location_params))
        contact_params.merge!(location_id: location.id)
      end
      contact = DataPlugins::Contact::Contact.create(contact_params)

      params[:contact_persons].each do |cp_params|
        contact_person_params =
          cp_params.permit(*self.class.contact_person_params).merge(contact_id: contact.id)
        contact_persons << DataPlugins::Contact::ContactPerson.create(contact_person_params)
      end
    end
    contact
  end

  module ClassMethods
    def contact_params
      [:id, :title, :web, :social_media, :spoken_languates, :fax, :location_id]
    end

    def contact_person_params
      [:name, :role, :mail, :phone]
    end
  end

end
