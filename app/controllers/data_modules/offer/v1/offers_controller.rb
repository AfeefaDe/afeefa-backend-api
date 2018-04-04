class DataModules::Offer::V1::OffersController < Api::V1::BaseController

  before_action :find_offer, only: [:update, :destroy]

  def create
    offer = DataModules::Offer::Offer.save_offer(params)
    render status: :created, json: offer
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

  private

  def base_for_find_objects
    DataModules::Offer::Offer.by_area(current_api_v1_user.area)
  end

  def find_offer
    @offer = DataModules::Offer::Offer.find(params[:id])
  end

end
