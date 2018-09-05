class Api::V1::AnnotationsController < Api::V1::BaseController

  before_action :find_owner

  # POST :owner_type/:owner_id/annotations
  def create
    contact = @owner.save_annotation(params)
    render status: :created, json: contact
  end

  # GET :owner_type/:owner_id/annotations
  def index
    render status: :ok, json: @owner.annotations
  end

  # PUT :owner_type/:owner_id/annotations/:id
  def update
    contact = @owner.save_annotation(params)
    render status: :ok, json: contact
  end

  # DELETE :owner_type/:owner_id/annotations/:id
  def delete
    if @owner.delete_annotation(params)
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
