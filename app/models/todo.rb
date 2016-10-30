class Todo
  include ActiveModel::Model

  def id
    1
  end

  def orgas
    Orga.undeleteds.annotateds.map do |orga|
      JSONAPI::ResourceSerializer.new(Api::V1::OrgaResource).serialize_to_hash(Api::V1::OrgaResource.new(orga, nil))
    end
  end

  def events
    Event.undeleteds.annotateds.map do |event|
      JSONAPI::ResourceSerializer.new(Api::V1::EventResource).serialize_to_hash(Api::V1::EventResource.new(event, nil))
    end

  end
end
