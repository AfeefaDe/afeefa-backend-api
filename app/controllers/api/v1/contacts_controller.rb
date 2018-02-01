class Api::V1::ContactsController < Api::V1::BaseController

  skip_before_action :find_objects, only: %i(update delete)
  before_action :find_owner

  def create
    if contact = @owner.save_contact(params)
      render status: :created, json: contact
    else
      render status: :unprocessable_entity
    end
  end

  def update
    if contact = @owner.save_contact(params)
      render status: :ok, json: contact
    else
      render status: :unprocessable_entity
    end
  end

  def delete
    if @owner.delete_contact(params)
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  private

  def find_owner
    @owner =
      case params[:owner_type]
      when 'orgas'
        Orga.find(params[:owner_id])
      end
    unless @owner
      raise ActiveRecord::RecordNotFound,
        "Element mit ID #{params[:owner_id]} konnte für Typ #{params[:owner_type]} nicht gefunden werden."
    end
  end

end
