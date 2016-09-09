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
    res, op = Orga::CreateSubOrga.run(params.merge(user: current_api_v1_user)) do
      head :created
    end
  end

  def show
    # render json: @orga
  end

  def update
    Orga::Activate.run(params.merge(user: current_api_v1_user)) do
      head :no_content
    end
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
