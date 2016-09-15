class Api::V1::OrgasController < Api::V1::BaseController

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
    Orga::Operations::Update.run(params) do
      head :no_content
      return
    end
    head :unprocessable_entity
  end

  def destroy
    Orga::Operations::Delete.run(params) do
      head :no_content
    end
    head :unprocessable_entity
  end

end
