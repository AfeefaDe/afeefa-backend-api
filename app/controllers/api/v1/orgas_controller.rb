class Api::V1::OrgasController < Api::V1::BaseController

  # before_action :set_orga, except: [:index, :create]
  # before_action :set_user, only: [:remove_member, :promote_member, :demote_admin, :add_member]

  def index
    present Orga::Operations::Index
    render json: @model
  end

  def create
    Orga::Operations::CreateSubOrga.run(
        params.merge(user: current_api_v1_user)
    ) do
      head :created
      return
    end
    head :unprocessable_entity
  end

  def show
    present Orga::Operations::Show
    render json: @model
  end

  def update
    response, operation = Orga::Operations::Update.run(
        params.merge(user: current_api_v1_user)
    ) do
      head :no_content
    end
    head :unprocessable_entity
  end

  def destroy
    # current_api_v1_user.can! :write_orga_structure, @orga, 'You are not authorized to modify the structure of this organization!'
    # @orga.destroy!
    # head status: :no_content
  end

  private

  # def user_params
  #   params.require(:user).permit(:forename, :surname, :email)
  # end

  # def orga_params
  #   params.require(:data).permit(:id, :type, :attributes => [:title, :description])
  # end

  # def orgas_params
  #   params.permit(:page => [:number, :size])
  # end

  # def set_orga
  #   @orga = Orga.find(params[:id])
  # end

  # def set_user
  #   @user = User.find(params[:user_id])
  # end

end
