class Event < ApplicationRecord
  class Index < Trailblazer::Operation
    include Collection

    def model!(params)
      if params[:page]
        events = Event.page(params[:page][:number]).per(params[:page][:size])
      else
        events = Event.all
      end
    end
  end
end