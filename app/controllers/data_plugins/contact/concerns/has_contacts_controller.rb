module DataPlugins::Contact::Concerns::HasContactsController
  extend ActiveSupport::Concern

  def get_contacts
    find_actor
    render status: :ok, json: @actor.contacts_to_hash
  end

  def link_contacts
    find_actor

    begin
      add_association(params[:contact_id])
      head 201
    rescue
      head :unprocessable_entity
    end
  end

  private

  def find_actor
    # get model type by controller class
    type = self.class.name.to_s.demodulize.gsub(/Controller.*/, '').singularize.constantize
    @actor = type.find(params[:id])
  end

  def add_association(contact_id)
    contact = DataPlugins::Contact.find_by_id(contact_id)
    if contact.blank?
      raise 'Contact does not exist'
    end

    if contact_id == @actor.contact_id
      raise 'Association already exists'
    end

    unless @actor.area == contact.area
      raise 'Contact is in wrong area'
    end

    @actor.update(contact: contact)
  end
end
