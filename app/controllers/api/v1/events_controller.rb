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

  # def update
  #   event = Event.undeleted.find(params[:id])
  #   if event.update(map_params(resource_params))
  #     jsonapi_render json: event
  #   else
  #     jsonapi_render_errors json: event, status: :unprocessable_entity
  #   end
  # end
  #
  # protected
  #
  # def map_params(params)
  #   params[:time_start] = params.delete(:has_time_start)
  #   params[:time_end] = params.delete(:has_time_end)
  #   params.delete(:created_at)
  #   params.delete(:updated_at)
  #   pp params
  #   params
  # end

end
