class Api::V1::OrgasController < Api::V1::BaseController

  # before_action :set_orga, except: [:index, :create]
  # before_action :set_user, only: [:remove_member, :promote_member, :demote_admin, :add_member]

  def index
    # if orgas_params[:page]
    #   @orgas = Orga.page(orgas_params[:page][:number]).per(orgas_params[:page][:size])
    # else
    #   @orgas = Orga.all
    # end
    #
    # render json: @orgas
  end

  def create
    # params.merge!(user: current_api_v1_user)
    # run Orga::CreateSubOrga do
    #   head status: :created
    # end
  end

  def show
    # render json: @orga
  end

  def update
    # @orga.update_data(member: current_api_v1_user, data: orga_params[:attributes])
    # render json: @orga
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
