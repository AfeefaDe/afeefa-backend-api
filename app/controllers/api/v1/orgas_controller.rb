class Api::V1::OrgasController < Api::V1::BaseController

  # before_action :set_orga, except: [:index, :create]
  # before_action :set_user, only: [:remove_member, :promote_member, :demote_admin, :add_member]

  def index
    if params[:page]
      @orgas = Orga.page(params[:page][:number]).per(params[:page][:size])
    else
      @orgas = Orga.all
    end

    render json: @orgas
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
    # render json: @orga
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
    response, operation = Orga::Operations::Delete.run(
        params.merge(user: current_api_v1_user)
    ) do
      head :no_content
    end
    head :unprocessable_entity
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
