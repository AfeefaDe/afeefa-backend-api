class Api::V1::EntriesController < Api::V1::EntriesBaseController

  skip_before_action :find_objects
  before_action :custom_find_objects

  private

  def custom_find_objects
    orgas = Orga.all
    events = Event.all

    [orgas, events].each do |objects|
      if (filter = filter_params) && filter.respond_to?(:keys) && filter.keys.present?
        filter_params.each do |attribute, filter_criterion|
          if attribute.to_s.in?(filter_whitelist)
            objects = objects.where("#{attribute} LIKE ?", "%#{filter_criterion}%")
            if objects.first.is_a?(Orga)
              orgas = objects
            else
              events = objects
            end
          elsif attribute.to_s.in?(custom_filter_whitelist)
            objects = apply_custom_filter!(attribute, objects)
            if objects.first.is_a?(Orga)
              orgas = objects
            else
              events = objects
            end
          end
        end
      end
    end

    @objects = orgas + events
  end

end
