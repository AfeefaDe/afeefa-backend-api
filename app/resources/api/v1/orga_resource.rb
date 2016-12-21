class Api::V1::OrgaResource < Api::V1::EntriesBaseResource

  attributes *ATTRIBUTES

  has_one :parent_orga, class_name: 'Orga', foreign_key: 'parent_id'
  has_many :sub_orgas, class_name: 'Orga', foreign_key: 'children_ids'

  # has_many :events, class_name: 'Event'

end
