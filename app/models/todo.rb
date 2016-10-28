class Todo
  include ActiveModel::Model

  def self.all
    [new]
  end

  def self.where
    []
  end

  def id
    1
  end

  def orgas
    Orga.all#where(state: Thing::TODO_STATES).map { |o| JSONAPI::ResourceSerializer.new(Api::V1::OrgaResource).serialize_to_hash(Api::V1::OrgaResource.new(o, nil)) }
  end

  def events
    Event.all#where(state: Thing::TODO_STATES).map { |o| JSONAPI::ResourceSerializer.new(Api::V1::EventResource).serialize_to_hash(Api::V1::EventResource.new(o, nil)) }
  end
end
