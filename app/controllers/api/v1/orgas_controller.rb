class Api::V1::OrgasController < Api::V1::BaseController

  UPDATE_DATA = 'update_data'
  UPDATE_ALL = 'update_all'
  UPDATE_STRUCTURE = 'update_structure'
  UPDATE_OPERATIONS = [UPDATE_DATA, UPDATE_ALL, UPDATE_STRUCTURE]

  before_action :validate_meta, only: :update
  before_action :validate_right_read, only: [:index, :show]
  # before_action :validate_right_write_data, only: [:show]
  before_action :validate_right_write_structure, only: [:delete, :create]

  private

  def validate_right_read
    orga = Orga.find(params[:id])
    can_read(orga)
  end

  def validate_right_write_data
    orga = Orga.find(params[:id])
    can_write_data(orga)
  end

  def validate_right_write_structure
    orga = Orga.find(params[:id])
    can_write_structure(orga)
    false
  end

  def can_read(orga)
    current_api_v1_user.can! :read_orga, orga, 'You are not authorized to see this organization!'
  end

  def can_write_data(orga)
    current_api_v1_user.can! :write_orga_data, orga, 'You are not authorized to modify the data of this organization!'
  end

  def can_write_structure(orga)
    current_api_v1_user.can! :write_orga_structure, orga, 'You are not authorized to modify the structure of this organization!'
  end

  def validate_meta
    if (params[:meta].nil? || params[:meta][:trigger_operation].nil?) ||
        !UPDATE_OPERATIONS.include?(params[:meta][:trigger_operation])
      head :bad_request
      false
    else
      orga = Orga.find(params[:id])
      case params[:meta][:trigger_operation]
        when UPDATE_DATA
          can_write_data(orga)
          true
        when UPDATE_STRUCTURE
          can_write_structure(orga)
          true
        when UPDATE_ALL
          can_write_data(orga)
          can_write_structure(orga)
          true
        else
          head :bad_request
          false
      end
    end
  end

  # def index
  #   present Orga::Operations::Index
  #   render json: @model
  # end
  #
  # def create
  #   Orga::Operations::CreateSubOrga.run(params) do
  #     # head :created
  #     super
  #     return
  #   end
  #   head :unprocessable_entity
  # end
  #
  # def show
  #   present Orga::Operations::Show
  #   render json: @model
  # end
  #
  # def update
  #   if (params[:meta].nil? || params[:meta][:trigger_operation].nil?) ||
  #       !UPDATE_OPERATIONS.include?(params[:meta][:trigger_operation])
  #     head :bad_request
  #   else
  #     case params[:meta][:trigger_operation]
  #       when UPDATE_DATA
  #         Orga::Operations::UpdateData.run(params) do
  #           head :no_content
  #           return
  #         end
  #       when UPDATE_ALL
  #         Orga::Operations::UpdateAll.run(params) do
  #           head :no_content
  #           return
  #         end
  #       when UPDATE_STRUCTURE
  #         Orga::Operations::UpdateStructure.run(params) do
  #           head :no_content
  #           return
  #         end
  #       else
  #         head :bad_request
  #     end
  #   end
  # end
  #
  #
  # def destroy
  #   Orga::Operations::Delete.run(params) do
  #     head :no_content
  #   end
  #   head :unprocessable_entity
  # end
end