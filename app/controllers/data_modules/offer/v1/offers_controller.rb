class DataModules::Offer::V1::OffersController < Api::V1::BaseController

  before_action :find_offer, only: [:show, :update, :destroy, :link_owners, :get_owners]

  def show
    # put more details into the offer.owners list @see offer#owners_to_hash
    owners_hash = @offer.owners.map { |o| o.to_hash }
    offer_hash = @offer.as_json
    offer_hash[:relationships][:owners] = { data: owners_hash }
    render status: :ok, json: { data: offer_hash }
  end

  def index
    area = current_api_v1_user.area

    if params[:ids]
      offers = DataModules::Offer::Offer.
        all_for_ids(params[:ids].split(/,/)).
        map do |offer|
          offer.to_hash(
            attributes: DataModules::Offer::Offer.default_attributes_for_json,
            relationships: DataModules::Offer::Offer.default_relations_for_json)
        end
    else
      offers = DataModules::Offer::Offer.includes(DataModules::Offer::Offer.lazy_includes).
        by_area(area).
        map do |offer|
          offer.serialize_lazy
        end
    end

    render status: :ok, json: { data: offers }
  end

  def create
    begin
      ActiveRecord::Base.transaction do # fail if one fails
        params[:area] = current_api_v1_user.area
        offer = DataModules::Offer::Offer.save_offer(params)

        owners = params[:owners] || []
        owners.each do |owner_id|
          owner = offer.link_owner(owner_id)

          if !offer.linked_contact && owner.contacts.present?
            offer.link_contact!(owner.contacts.first.id)
          end
        end
        render status: :created, json: offer
      end
    rescue ActiveRecord::RecordInvalid
      raise # let base controller handle
    rescue
      head :unprocessable_entity
    end
  end

  def update
    offer = DataModules::Offer::Offer.save_offer(params)
    render status: :ok, json: offer
  end

  def destroy
    if @offer.destroy
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  def link_owners
    begin
      ActiveRecord::Base.transaction do # fail if one fails
        @offer.owners.destroy_all
        actor_ids = params[:actors] || [] # https://github.com/rails/rails/issues/26569
        actor_ids.each do |actor_id|
          @offer.link_owner(actor_id)
        end
        head 201
      end
    rescue
      head :unprocessable_entity
    end
  end

  def get_owners
    render status: :ok, json: @offer.owners_to_hash
  end

  def convert_from_actor
    begin
      ActiveRecord::Base.transaction do # fail if one fails
        params[:area] = current_api_v1_user.area
        offer = DataModules::Offer::Offer.save_offer(params)

        # link new offer owners
        owners = params[:owners] || []
        owners.each do |owner_id|
          offer.link_owner(owner_id)
        end

        actor = Orga.find(params[:actorId])

        # relink contact, location, navigation
        DataPlugins::Contact::Contact.where(owner: actor).update(owner: offer)
        if actor.linked_contact
          offer.update(linked_contact: actor.linked_contact)
        end

        DataPlugins::Location::Location.where(owner: actor).update(owner: offer)
        DataModules::FeNavigation::FeNavigationItemOwner.where(owner: actor).update(owner: offer)

        # move actor events to all specfied offer owners
        events = actor.events
        events.each do |event|
          offer.owners.each do |owner|
            event.hosts << owner
          end
        end

        # move actor projects to all specfied offer owners
        projects = actor.projects
        projects.each do |project|
          offer.owners.each do |owner|
            owner.projects << project
          end
        end

        # move actor offers to all specfied offer owners
        offers = actor.offers
        offers.each do |actor_offer|
          offer.owners.each do |owner|
            owner.offers << actor_offer
          end
        end

        # skip set entry validation for annotations
        annotations = Annotation.where(entry: actor)
        annotations.each do |annotation|
          annotation.entry = offer
          annotation.save(validate: false)
        end

        actor.destroy

        render status: :created, json: offer
      end
    rescue ActiveRecord::RecordInvalid
      raise # let base controller handle
    rescue
      head :unprocessable_entity
    end
  end

  private

  def base_for_find_objects
    DataModules::Offer::Offer.by_area(current_api_v1_user.area)
  end

  def find_offer
    @offer = DataModules::Offer::Offer.find(params[:id])
  end

end
