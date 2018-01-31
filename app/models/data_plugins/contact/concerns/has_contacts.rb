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

  def save_contact(params)
    contact = nil
    success = true
    contact_persons = []
    ActiveRecord::Base.transaction do
      contact_params = params.permit(*self.class.contact_params)

      unless params.key?(:location_id)
        if params.key?(:location)
          # We assume that our own class knows about location_params, it has to include HasLocations
          location_params = params.fetch(:location, {}).permit(*self.class.location_params)
          location = DataPlugins::Location::Location.create(location_params)
          success = success && true
          contact_params.merge!(location_id: location.id)
        end
      end

      if success
        if params[:action] == 'create'
          contact = DataPlugins::Contact::Contact.create(contact_params)
          success = success && contact.persisted?
        elsif params[:action] == 'update'
          contact = DataPlugins::Contact::Contact.find(params[:contact_id])
          contact.contact_persons.destroy_all
          success = success && contact.contact_persons.blank?
          success = success && contact.update(contact_params)
          if params.key?(:location_id)
            unless params[:location_id]
              # TODO: Needs to be tested!
              if contact && contact.location && contact.owner == contact.location.owner
                success = success && contact.location.delete
              end
            end
          end
        end
      end

      if success
        params[:contact_persons].each do |cp_params|
          contact_person_params =
            cp_params.permit(*self.class.contact_person_params).merge(contact_id: contact.id)
          contact_person = DataPlugins::Contact::ContactPerson.create(contact_person_params)
          contact_persons << contact_person
          success = success && contact_person.persisted?
        end
      end
    end

    if success
      contact.reload
    end
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
