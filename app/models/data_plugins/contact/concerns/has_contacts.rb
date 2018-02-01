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
    success = true
    contact = nil

    ActiveRecord::Base.transaction do
      contact_params = params.permit(*self.class.contact_params)

      # create or update contact
      if params[:action] == 'create'
        contact_params.merge!(owner: self)
        contact = DataPlugins::Contact::Contact.create(contact_params)
        success = contact.persisted?
      elsif params[:action] == 'update'
        contact = DataPlugins::Contact::Contact.find(params[:contact_id])
        success = success && contact.update(contact_params)
      end

      # remove existing contact persons
      if success
        contact.contact_persons.destroy_all
        success = contact.contact_persons.blank?
      end

      # save contact persons
      if success
        params[:contact_persons].each do |cp_params|
          contact_person_params =
            cp_params.permit(*self.class.contact_person_params).merge(contact_id: contact.id)
          contact_person = DataPlugins::Contact::ContactPerson.create(contact_person_params)
          success = success && contact_person.persisted?
        end
      end

      # create or update location
      if success
        unless params.key?(:location_id) # :location_id gets precedence over :location
          if params.key?(:location)
            # We assume that our own class knows about location_params, it has to include HasLocations
            location_params = params.fetch(:location, {}).permit(*self.class.location_params)
            location_params.merge!(owner: self)

            if contact.location
              success = contact.location.update(location_params)
            else
              location = DataPlugins::Location::Location.create(location_params)
              success = location.persisted?
              params.merge!(location_id: location.id)
            end
          end
        end
      end

      # set location reference
      if success
        if params.key?(:location_id)
          if params[:location_id]
            success = success && contact.update({location_id: params[:location_id]})
          else
            # TODO: Needs to be tested!
            # if we set location_id to null, we want to remove the contact's own location
            if contact && contact.location && contact.owner == contact.location.owner
              success = success && contact.location.delete
            end
          end
        end
      end
    end

    if success
      contact.reload
    end
  end

  module ClassMethods
    def contact_params
      [:id, :title, :web, :social_media, :opening_hours, :spoken_languages, :fax, :location_id]
    end

    def contact_person_params
      [:name, :role, :mail, :phone]
    end
  end

end
