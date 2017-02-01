class Api::V1::EventsController < Api::V1::BaseController

  # def destroy
  #   super
  # end

  def index
    events = Event.undeleted
    if params[:filter] && params[:filter][:title]
      events = events.where('title LIKE ?', "%#{params[:filter][:title]}%")
    end
    jsonapi_render json: events.to_a
  end

  def show
    jsonapi_render json: Event.undeleted.find(params[:id])
  end

end
