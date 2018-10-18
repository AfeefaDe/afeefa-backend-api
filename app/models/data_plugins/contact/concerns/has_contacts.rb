module DataPlugins::Contact::Concerns::HasContacts
  extend ActiveSupport::Concern

  included do
    # ASSOCIATIONS
    has_many :contacts, class_name: DataPlugins::Contact::Contact, as: :owner, dependent: :restrict_with_exception
    belongs_to :linked_contact, class_name: DataPlugins::Contact::Contact, foreign_key: :contact_id
  end

  def delete_contact(params)
    ActiveRecord::Base.transaction do
      contact = ensure_contact_if_id_param_is_given!(params[:id])
      ensure_given_contact_is_linked!(contact.id)
      update!(linked_contact: nil)
      if own_contact?(contact.id)
        contact.destroy!
      else
        true
      end
    end
  end

  def save_contact(params)
    contact = nil

    ActiveRecord::Base.transaction do
      contact_params = params.permit(*self.class.contact_params)
      contact = ensure_contact_if_id_param_is_given!(params[:id])

      if params[:action] == 'create'
        ensure_no_linked_contact_given!
        ensure_no_owned_contact_given!
      elsif params[:action] == 'update'
        ensure_given_contact_is_an_owned_contact_and_is_linked!(contact.id)
      end

      has_attribute_params = true
      if params[:action] == 'create' && params[:id].present?
        ensure_contact_can_be_linked!(contact)
        has_attribute_params = false
      end

      if has_attribute_params
        # create or update contact
        if params[:action] == 'create'
          contact_params = contact_params.merge(owner: self)
          contact = DataPlugins::Contact::Contact.create!(contact_params)
        elsif params[:action] == 'update'
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

        # if location_id is null -> remove own location
        if params.has_key?(:location_id) && params[:location_id].blank?
          if contact.location && contact.location.contact == contact
            contact.location.delete
          end
          contact.update!(
            location_id: nil
          )
        end

        # set location reference
        if params[:location_id].present?
          linked_location = ensure_location_if_id_param_is_given!(params[:location_id])

          # if location_id changes, delete old location, if own location
          if contact.location
            if contact.location.id != linked_location.id
              if contact.location.contact == contact
                contact.location.delete
              end
            end
          end

          # link new location
          unless contact.location_id == linked_location.id
            contact.update!(
              location_id: linked_location.id
            )
            # clear location_spec if not given
            unless params.has_key?(:location_spec)
              contact.update!(
                location_spec: nil
              )
            end
          end
        end
      end

      # remove contact_spec if linking a new contact
      unless linked_contact.try(:id) == contact.id
        update!(contact_spec: nil)
        link_contact!(contact.id)
      end
    end

    contact.reload
  end

  def link_contact!(contact_id)
    # link contact to owner
    update!(contact_id: contact_id)
  end

  def ensure_no_linked_contact_given!
    if linked_contact.present?
      raise Errors::NotPermittedException, 'There is already a linked contact given.'
    end
  end

  def ensure_no_owned_contact_given!
    if contacts.any?
      raise Errors::NotPermittedException, 'There is already an owned contact given.'
    end
  end

  def ensure_given_contact_is_an_owned_contact_and_is_linked!(contact_id)
    ensure_given_contact_is_linked!(contact_id)
    unless own_contact?(contact_id)
      raise Errors::NotPermittedException, 'The given contact is not owned by you.'
    end
  end

  def own_contact?(contact_id)
    contacts.pluck(:id).include?(contact_id)
  end

  def ensure_given_contact_is_linked!(contact_id)
    unless linked_contact.try(:id) == contact_id
      raise Errors::NotPermittedException, 'The given contact is not linked by you.'
    end
  end

  def ensure_contact_if_id_param_is_given!(id)
    if id.present?
      contact = DataPlugins::Contact::Contact.find(id)
      raise ActiveRecord::RecordNotFound if contact.nil?
      contact
    end
  end

  def ensure_location_if_id_param_is_given!(id)
    if id.present?
      location = DataPlugins::Location::Location.find(id)
      raise ActiveRecord::RecordNotFound if location.nil?
      location
    end
  end

  def ensure_contact_can_be_linked!(contact)
    unless contact.owner.instance_of? Orga
      raise Errors::NotPermittedException, 'The given contact cannot be linked.'
    end
  end

  def linked_contacts_to_hash(attributes: nil, relationships: nil)
    [linked_contact&.to_hash].compact
  end
  # json api alias
  alias :contacts_to_hash :linked_contacts_to_hash

  module ClassMethods
    def contact_params
      [:id, :title, :web, :social_media, :opening_hours, :spoken_languages, :location_spec]
    end

    def contact_person_params
      [:name, :role, :mail, :phone]
    end
  end
end
