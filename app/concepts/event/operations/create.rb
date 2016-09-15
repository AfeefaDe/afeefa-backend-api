class Event < ApplicationRecord
  module Operations
    class Create < Trailblazer::Operation

      include Model
      model Event, :create

      contract Event::Forms::CreateForm

      def process(params)
        validate(params[:data][:attributes]) do |new_event_form|
          # TODO: check permissions etc.
          new_event_form.save
          unless params[:owner].nil?
            OwnerThingRelation.create!(ownable: @model, thingable: params[:owner])
          end
        end
      end

    end
  end
end
