class Api::V1::ContactsController < Api::V1::BaseController

  def create
    orga = Orga.find(params[:id])
    if contact = orga.create_contact(params)
      render status: :created, json: contact
    end
  end

end
