class Api::V1::OrgaResource < Api::V1::BaseResource
  attributes :title, :description, :created_at, :updated_at, :active, :state, :category

  has_one :parent_orga, class_name: 'Orga', foreign_key: 'parent_id'
  has_many :sub_orgas, class_name: 'Orga', foreign_key: 'children_ids'

  has_many :users
end
