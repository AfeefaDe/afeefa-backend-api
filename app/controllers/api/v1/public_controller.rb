class Api::V1::PublicController < Api::V1::EntriesBaseController
  skip_before_action :authenticate_api_v1_user!

  def show_actor
    area = params[:area]

    orga = Orga.where(state: 'active').by_area(area).find(params[:id])
    # put more details into the orga.project_intitators list @see orga#project_initiators_to_hash
    initiators_hash = orga.project_initiators.map { |i| i.to_hash }
    orga_hash = orga.as_json(public: true)
    orga_hash[:relationships][:project_initiators] = { data: initiators_hash }
    render status: :ok, json: { data: orga_hash }
  end

  def index_actors
    area = params[:area]

    if params[:ids]
      orgas =
        Orga.where(state: 'active').
          by_area(area).
          all_for_ids(params[:ids].split(/,/)).
          map do |orga|
            orga.
              as_json(
                attributes: Orga.default_attributes_for_json,
                relationships: Orga.default_relations_for_json,
                public: true
              )
          end
    else
      orgas =
        Orga.where(state: 'active').includes(Orga.lazy_includes).
          by_area(area).
          map do |orga|
            orga.serialize_lazy(public: true)
          end
    end

    render status: :ok, json: { data: orgas }
  end

  def show_event
    area = params[:area]

    event = Event.where(state: 'active').upcoming.by_area(area).find(params[:id])
    # put more details into the event.hosts list @see event#hosts_to_hash
    hosts_hash = event.hosts.map { |h| h.to_hash }
    event_hash = event.as_json(public: true)
    event_hash[:relationships][:hosts] = { data: hosts_hash }
    render status: :ok, json: { data: event_hash }
  end

  def index_events
    area = params[:area]

    if params[:ids]
      events =
        Event.where(state: 'active').upcoming.
          by_area(area).
          all_for_ids(params[:ids].split(/,/)).
          map do |event|
            event.as_json(
              attributes: Event.default_attributes_for_json,
              relationships: Event.default_relations_for_json,
              public: true
            )
          end
    else
      events =
        Event.where(state: 'active').upcoming.
          includes(Event.lazy_includes).
          by_area(area).
          map do |event|
            event.serialize_lazy(public: true)
          end
    end

    render status: :ok, json: { data: events }
  end

  def show_offer
    # put more details into the offer.owners list @see offer#owners_to_hash
    area = params[:area]
    offer = DataModules::Offer::Offer.where(active: true).by_area(area).find(params[:id])
    owners_hash = offer.owners.map { |o| o.to_hash }
    offer_hash = offer.as_json(public: true)
    offer_hash[:relationships][:owners] = { data: owners_hash }
    render status: :ok, json: { data: offer_hash }
  end

  def index_offers
    area = params[:area]

    if params[:ids]
      offers =
        DataModules::Offer::Offer.
          where(active: true).
          by_area(area).
          all_for_ids(params[:ids].split(/,/)).
          map do |offer|
            offer.to_hash(
              attributes: DataModules::Offer::Offer.default_attributes_for_json,
              relationships: DataModules::Offer::Offer.default_relations_for_json,
              public: true
            )
          end
    else
      offers =
        DataModules::Offer::Offer.includes(DataModules::Offer::Offer.lazy_includes).
          where(active: true).
          by_area(area).
          map do |offer|
            offer.serialize_lazy(public: true)
          end
    end

    render status: :ok, json: { data: offers }
  end

  def show_navigation
    area = params[:area]

    navigation =
      DataModules::FeNavigation::FeNavigation.
        includes(
          [
            {
              navigation_items:
                [
                  {
                    sub_items: [:sub_items]
                  }
                ]
            }
          ]
        ).
        by_area(area).
        take
    render json: navigation.as_json(public: true)
  end

  def index_facets
    area = params[:area]
    objects = DataPlugins::Facet::Facet.all
    render_objects_to_json(objects)
  end

  def show_facet
    area = params[:area]
    objects = DataModule::Facet::Facet.all
    object = objects.find(params[:id])
    render_single_object_to_json(object)
  end

  private

  def render_objects_to_json(objects)
    json_hash =
      objects.try do |objects_in_try|
        objects_in_try.map do |object|
          object.try(:send, to_hash_method, public: true)
        end
      end || []
    render json: { data: json_hash }
  end

  def render_single_object_to_json(object, status: nil)
    render(
      status: status || 200,
      json: {
        data:
          object.send(to_hash_method,
            attributes: object.class.attribute_whitelist_for_json,
            relationships: object.class.relation_whitelist_for_json,
            public: true
          )
      }
    )
  end

  def to_hash_method
    :to_hash
  end

  def default_filter
    { area: params[:area] }
  end
end
