class DataModules::Offer::V1::OffersController < Api::V1::BaseController

  before_action :find_offer, only: [:show, :update, :destroy, :link_owners, :get_owners]

  def show
    # put more details into the offer.owners list @see offer#owners_to_hash
    owners_hash = @offer.owners.map { |o| o.to_hash }
    offer_hash = @offer.to_hash
    offer_hash[:relationships][:owners] = { data: owners_hash }
    render status: :created, json: { data: offer_hash }
  end

  def create
    begin
      ActiveRecord::Base.transaction do # fail if one fails
        params[:area] = current_api_v1_user.area
        offer = DataModules::Offer::Offer.save_offer(params)

        actors = params[:actors] || []
        actors.each do |actor_id|
          offer.link_owner(actor_id)
        end
        render status: :created, json: offer
      end
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

  private

  def base_for_find_objects
    DataModules::Offer::Offer.by_area(current_api_v1_user.area)
  end

  def find_offer
    @offer = DataModules::Offer::Offer.find(params[:id])
  end

end
