class Api::V1::OrgaResource < Api::V1::BaseResource

  attributes :title, :description, :created_at, :updated_at,
             :state_changed_at, :state, :state_transition,
             :category

  has_one :parent_orga, class_name: 'Orga', foreign_key: 'parent_id'
  has_many :sub_orgas, class_name: 'Orga', foreign_key: 'children_ids'

  has_many :annotations, class_name: 'Annotation'
  has_many :locations, class_name: 'Location'
  has_many :contact_infos, class_name: 'ContactInfo'

  filter :todo, apply: ->(records, value, _options) {
    records.annotated
  }

  filter :title, apply: ->(records, value, _options) {
    records.where('title LIKE ?', "%#{value[0]}%")
  }

  filter :description, apply: ->(records, value, _options) {
    records.where('description LIKE ?', "%#{value[0]}%")
  }

end
