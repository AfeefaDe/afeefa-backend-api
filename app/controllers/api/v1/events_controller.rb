class Api::V1::EventsController < Api::V1::EntriesBaseController
  def show
    area = current_api_v1_user.area
    event = Event.by_area(area).find(params[:id])
    # put more details into the event.hosts list @see event#hosts_to_hash
    hosts_hash = event.hosts.map { |h| h.to_hash }
    event_hash = event.as_json
    event_hash[:relationships][:hosts] = { data: hosts_hash }
    render status: :ok, json: { data: event_hash }
  end

  def index
    area = current_api_v1_user.area

    if params[:ids]
      events = Event.
        by_area(area).
        all_for_ids(params[:ids].split(/,/)).
        map do |event|
          event.to_hash(attributes: Event.default_attributes_for_json, relationships: Event.default_relations_for_json)
        end
    else
      events = filter_objects.
        includes(Event.lazy_includes).
        by_area(area).
        map do |event|
          event.serialize_lazy
        end
    end

    render status: :ok, json: { data: events }
  end

  def create
    begin
      ActiveRecord::Base.transaction do # fail if one fails
        params[:data][:attributes][:area] = current_api_v1_user.area
        event = Event.create_event(params)

        hosts = params.dig(:data, :relationships, :hosts) || []
        hosts.each do |host_id|
          host = event.link_host(host_id)

          if !event.linked_contact && host.contacts.present?
            event.link_contact!(host.contacts.first.id)
          end
        end

        render status: :created, json: { data: event }
      end
    rescue ActiveRecord::RecordInvalid
      raise # let base controller handle
    rescue
      head :unprocessable_entity
    end
  end

  def get_hosts
    area = current_api_v1_user.area
    event = Event.by_area(area).find(params[:id])
    render status: :ok, json: event.hosts_to_hash
  end

  def link_hosts
    area = current_api_v1_user.area
    event = Event.by_area(area).find(params[:id])
    begin
      ActiveRecord::Base.transaction do # fail if one fails
        event.hosts.destroy_all
        actor_ids = params[:actors] || [] # https://github.com/rails/rails/issues/26569
        actor_ids.each do |actor_id|
          event.link_host(actor_id)
        end
        head 201
      end
    rescue
      head :unprocessable_entity
    end
  end

  def custom_filter_whitelist
    (super.deep_dup + %w(date)).freeze
  end

  def apply_custom_filter!(filter, filter_criterion, objects)
    objects = super
    objects =
      case filter.to_sym
        when :date
          case filter_criterion.to_sym
            when :upcoming
              objects.upcoming
            when :past
              objects.past
            else
              objects
          end
        else
          objects
      end
    objects
  end
end
