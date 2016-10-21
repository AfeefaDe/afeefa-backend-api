class Api::V1::OrgaResource < Api::V1::BaseResource
  attributes :title, :description, :created_at, :updated_at, :active, :state

  has_one :parent, class_name: 'Orga'
  has_many :children, clas_name: 'Orga'

  has_many :users
end
