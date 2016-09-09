class Api::V1::OrgasController < Api::V1::BaseController

  before_action :set_orga, except: [:index, :create]
  before_action :set_user, only: [:remove_member, :promote_member, :demote_admin, :add_member]

  def show
    render json: @orga
  end

  def index
    if orgas_params[:page]
      @orgas = Orga.page(orgas_params[:page][:number]).per(orgas_params[:page][:size])
    else
      @orgas = Orga.all
    end

    render json: @orgas
  end

  def create_member
    new_member =
        current_api_v1_user.create_user_and_add_to_orga(
            orga: Orga.find(params[:id]),
            forename: user_params[:forename],
            surname: user_params[:surname],
            email: user_params[:email]
        )
    render json: new_member, status: :created
  end

  def add_member
    @orga.add_new_member(new_member: @user, admin: current_api_v1_user)
    head status: :no_content
  end

  def remove_member
    if current_api_v1_user == @user
      current_api_v1_user.leave_orga(orga: @orga)
    else
      current_api_v1_user.remove_user_from_orga(member: @user, orga: @orga)
    end
    head status: :no_content
  end

  def promote_member
    current_api_v1_user.promote_member_to_admin(member: @user, orga: @orga)
    head status: :no_content
  end

  def demote_admin
    current_api_v1_user.demote_admin_to_member(member: @user, orga: @orga)
    head status: :no_content
  end

  def list_members
    members = @orga.list_members(member: current_api_v1_user)
    render json: members
  end

  def update
    @orga.update_data(member: current_api_v1_user, data: orga_params[:attributes])
    render json: @orga
  end

  def destroy
    current_api_v1_user.can! :write_orga_structure, @orga, 'You are not authorized to modify the structure of this organization!'
    @orga.destroy!
    head status: :no_content
  end

  def create
    params.merge!(user: current_api_v1_user)
    run Orga::CreateSubOrga do
      head status: :created
    end
  end

  def activate
    @orga.change_active_state(admin: current_api_v1_user, active: true)
    head status: :no_content
  end

  def deactivate
    @orga.change_active_state(admin: current_api_v1_user, active: false)
    head status: :no_content
  end

  private

  def user_params
    params.require(:user).permit(:forename, :surname, :email)
  end

  def orga_params
    params.require(:data).permit(:id, :type, :attributes => [:title, :description])
  end

  def orgas_params
    params.permit(:page => [:number, :size])
  end

  def set_orga
    @orga = Orga.find(params[:id])
  end

  def set_user
    @user = User.find(params[:user_id])
  end

end
