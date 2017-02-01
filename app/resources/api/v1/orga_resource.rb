class Api::V1::OrgaResource < Api::V1::EntriesBaseResource

  model_name 'Orga'

  attributes *ATTRIBUTES

  has_one :parent_orga, class_name: 'Orga', foreign_key: 'parent_id'
  has_many :sub_orgas, class_name: 'Orga', foreign_key: 'children_ids'

  # has_many :events, class_name: 'Event'

  # # use this method instead of default scopes at the model
  # def self.records(options = {})
  #   super.without_root.undeleted
  # end

end
