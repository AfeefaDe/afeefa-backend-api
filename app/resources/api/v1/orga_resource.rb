class Api::V1::OrgaResource < Api::V1::EntriesBaseResource

  model_name 'Orga'

  attributes *ATTRIBUTES

  has_one :parent_orga, class_name: 'Orga', foreign_key: 'parent_id'
  has_many :sub_orgas, class_name: 'Orga', foreign_key: 'children_ids'

  has_many :events, class_name: 'Event'
  has_many :resource_items, class_name: 'ResourceItem'

  before_create do
    @model.creator_id = context[:current_user].id
    @model.last_editor_id = context[:current_user].id
  end

  before_update do
    @model.creator_id = context[:current_user].id
    @model.last_editor_id = context[:current_user].id
  end

  before_save do
    @model.creator_id = context[:current_user].id
    @model.last_editor_id = context[:current_user].id
  end

end
