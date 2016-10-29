class Api::V1::OrgaResource < Api::V1::BaseResource
  attributes :title, :description, :created_at, :updated_at, :state_changed_at, :active, :state, :category

  has_one :parent_orga, class_name: 'Orga', foreign_key: 'parent_id'
  has_many :sub_orgas, class_name: 'Orga', foreign_key: 'children_ids'

  has_one :annotation, class_name: 'Annotation', foreign_key: 'annotateable_id'
  has_one :location, class_name: 'Location', foreign_key: 'locateable_id'
  has_one :contact_info, class_name: 'ContactInfo', foreign_key: 'contactable_id'

  filter :title, apply: ->(records, value, _options) {
    records.where('title like ?', value)
  }
end
