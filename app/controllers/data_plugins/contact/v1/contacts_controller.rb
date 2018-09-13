class DataPlugins::Contact::V1::ContactsController < Api::V1::BaseController

  skip_before_action :find_objects
  before_action :find_owner, except: :get_contacts

  def get_contacts
    area = current_api_v1_user.area
    query = DataPlugins::Contact::Contact.
      selectable_in_area(area).
      includes(:owner, :location, :contact_persons)

    contacts = query.all.map do |contact|
      contact.to_hash(
        attributes: nil,
        dependent_attributes: { location: %i(street zip city) },
        dependent_relationships: { location: nil }
      )
    end

    render status: :ok, json: contacts
  end

  def index
    render status: :ok, json: @owner.contacts_to_hash
  end

  def create
    contact = @owner.save_contact(params)
    render status: :created, json: contact
  rescue Errors::NotPermittedException => exception
    render status: :unprocessable_entity, json: { error: exception.message }
  end

  def update
    contact = @owner.save_contact(params)
    render status: :ok, json: contact
  rescue Errors::NotPermittedException => exception
    render status: :unprocessable_entity, json: { error: exception.message }
  end

  def delete
    if @owner.delete_contact(params)
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  rescue Errors::NotPermittedException => exception
    render status: :unprocessable_entity, json: { error: exception.message }
  end

  private

  def find_owner
    @owner =
      case params[:owner_type]
      when 'orgas'
        Orga.find(params[:owner_id])
      when 'events'
        Event.find(params[:owner_id])
      when 'offers'
        DataModules::Offer::Offer.find(params[:owner_id])
      end
    unless @owner
      raise ActiveRecord::RecordNotFound,
        "Element mit ID #{params[:owner_id]} konnte für Typ #{params[:owner_type]} nicht gefunden werden."
    end
  end

end
