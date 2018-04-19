class Api::V1::EventsController < Api::V1::EntriesBaseController

  def show
    event = Event.find(params[:id])
    # put more details into the event.hosts list @see event#hosts_to_hash
    hosts_hash = event.hosts.map { |h| h.to_hash }
    event_hash = event.as_json
    event_hash[:relationships][:hosts] = { data: hosts_hash }
    render status: :ok, json: { data: event_hash }
  end

  def get_hosts
    event = Event.find(params[:id])
    render status: :ok, json: event.hosts_to_hash
  end

  def link_hosts
    event = Event.find(params[:id])
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

  def do_includes!(objects)
    objects.includes(Event.default_includes)
  end

end
