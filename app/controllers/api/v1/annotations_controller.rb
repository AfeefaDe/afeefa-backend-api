class Api::V1::AnnotationsController < Api::V1::BaseController

  before_action :find_owner, only: %i(get_owner_annotations)

  def get_owner_annotations
    render status: :ok, json: @owner.annotations
  end

  private

  def find_owner
    @owner =
      case params[:owner_type]
      when 'orgas'
        Orga.find(params[:owner_id])
      when 'events'
        Event.find(params[:owner_id])
      end
    unless @owner
      raise ActiveRecord::RecordNotFound,
        "Element mit ID #{params[:owner_id]} konnte für Typ #{params[:owner_type]} nicht gefunden werden."
    end
  end

end
