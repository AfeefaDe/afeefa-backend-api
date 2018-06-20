module DataPlugins::Contact::Concerns::HasContacts

  extend ActiveSupport::Concern

  included do
    # ASSOCIATIONS
    has_many :contacts, class_name: DataPlugins::Contact::Contact, as: :owner, dependent: :destroy

    has_one :main_contact, -> { DataPlugins::Contact::Contact.main.limit(1) },
      class_name: DataPlugins::Contact::Contact, as: :owner, dependent: :destroy

    has_many :sub_contacts, -> { DataPlugins::Contact::Contact.sub },
      class_name: DataPlugins::Contact::Contact, as: :owner, dependent: :destroy

    has_many :contact_persons, class_name: DataPlugins::Contact::ContactPerson, through: :contacts,
      dependent: :destroy
  end

  def delete_contact(params)
    ActiveRecord::Base.transaction do
      contact = DataPlugins::Contact::Contact.find(params[:id])
      raise ActiveRecord::RecordNotFound if contact.nil?
      return contact.destroy
    end
  end

  def save_contact(params)
    contact = nil

    ActiveRecord::Base.transaction do
      contact_params = params.permit(*self.class.contact_params)

      # create or update contact
      if params[:action] == 'create'
        contact_params = contact_params.merge(owner: self)
        contact = DataPlugins::Contact::Contact.create!(contact_params)
      elsif params[:action] == 'update'
        contact = DataPlugins::Contact::Contact.find(params[:id])
        raise ActiveRecord::RecordNotFound if contact.nil?
        contact.update!(contact_params)
      end

      # remove existing contact persons
      # :delete_all is needed to prevent from nullify association
      contact.contact_persons.delete_all(:delete_all)

      # save contact persons
      contact_persons = params[:contact_persons] || []
      contact_persons.each do |cp_params|
        contact_person_params =
          cp_params.permit(*self.class.contact_person_params).merge(contact_id: contact.id)
        DataPlugins::Contact::ContactPerson.create!(contact_person_params)
      end

      # create or update location
      if !params.has_key?(:location_id) && params.has_key?(:location) # :location_id gets precedence over :location
        # We assume that our own class knows about location_params, it has to include HasLocations
        location_params = params.fetch(:location, {}).permit(*self.class.location_params)
        location_params = location_params.merge(owner: self, contact: contact)

        if contact.location && contact.location.contact == contact
          contact.location.update!(location_params)
        else
          location = DataPlugins::Location::Location.create!(location_params)
          params = params.merge(location_id: location.id)
        end
      end

      # set location reference
      if params.has_key?(:location_id)
        # if location_id changes, delete old location, if own location
        if contact.location
          if contact.location.id != params[:location_id]
            if contact.location.contact == contact
              contact.location.delete
            end
          end
        end
        # set new location
        contact.update!({ location_id: params[:location_id] })
      end
    end

    contact.reload
  end

  module ClassMethods
    def contact_params
      [:id, :title, :web, :social_media, :opening_hours, :spoken_languages, :fax]
    end

    def contact_person_params
      [:name, :role, :mail, :phone]
    end
  end

end
