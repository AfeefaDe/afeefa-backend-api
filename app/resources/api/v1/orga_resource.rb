class Api::V1::OrgaResource < Api::V1::BaseResource
  attributes :title, :description, :created_at, :updated_at, :state_changed_at, :active, :state, :category

  has_one :parent_orga, class_name: 'Orga', foreign_key: 'parent_id'
  has_many :sub_orgas, class_name: 'Orga', foreign_key: 'children_ids'

  has_many :annotations, class_name: 'Annotation'
  has_many :locations, class_name: 'Location'
  has_many :contact_infos, class_name: 'ContactInfo'

  filter :title, apply: ->(records, value, _options) {
    records.where('title like ?', value)
  }
end
