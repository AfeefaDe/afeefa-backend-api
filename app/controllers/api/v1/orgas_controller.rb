class Api::V1::OrgasController < Api::V1::BaseController

  UPDATE_DATA = 'update_data'
  UPDATE_ALL = 'update_all'
  UPDATE_STRUCTURE = 'update_structure'
  UPDATE_OPERATIONS = [UPDATE_DATA, UPDATE_ALL, UPDATE_STRUCTURE]

  def index
    present Orga::Operations::Index
    render json: @model
  end

  def create
    Orga::Operations::CreateSubOrga.run(params) do
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
    if (params[:meta].nil? || params[:meta][:trigger_operation].nil?) ||
        !UPDATE_OPERATIONS.include?(params[:meta][:trigger_operation])
      head :bad_request
    else
      case params[:meta][:trigger_operation]
        when UPDATE_DATA
          Orga::Operations::UpdateData.run(params) do
            head :no_content
            return
          end
        when UPDATE_ALL
          Orga::Operations::UpdateAll.run(params) do
            head :no_content
            return
          end
        when UPDATE_STRUCTURE
          Orga::Operations::UpdateStrucure.run(params) do
            head :no_content
            return
          end
        else
          head :bad_request
      end
      head :unprocessable_entity
    end
  end


  def destroy
    Orga::Operations::Delete.run(params) do
      head :no_content
    end
    head :unprocessable_entity
  end
end