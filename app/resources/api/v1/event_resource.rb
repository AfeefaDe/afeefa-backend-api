class Api::V1::EventResource < Api::V1::EntriesBaseResource

  attributes *(ATTRIBUTES + [:date_start, :date_end])
  # not for now:
  # :public_speaker, :location_type, :support_wanted,

  # actual not needed (wait for ui)
  # has_one :parent_event, class_name: 'Event', foreign_key: 'parent_id'
  # has_many :sub_events, class_name: 'Event', foreign_key: 'children_ids'

  # has_many :ownables, class_name: 'Ownable'
  has_one :orga

  has_one :creator, class_name: 'User'

  before_create do
    @model.creator_id = context[:current_user].id
  end

  before_update do
    @model.creator_id = context[:current_user].id
  end

  before_save do
    @model.creator_id = context[:current_user].id
  end

end
