class Api::V1::EntryResource < Api::V1::BaseResource

  immutable
  abstract

  attributes :title, :description, :created_at, :updated_at,
             :state_changed_at, :state, :category

  def self.find(filters, options = {})
    orgas = Api::V1::OrgaResource.find(filters, options)
    events = Api::V1::EventResource.find(filters, options)

    orgas + events
  end

  def self.find_count(filters, options = {})
    orgas = Api::V1::OrgaResource.find_count(filters, options)
    events = Api::V1::EventResource.find_count(filters, options)

    orgas + events
  end

  filter :todo
  filter :title
  filter :description

end
