class Api::V1::EventResource < Api::V1::EntriesBaseResource

  model_name 'Event'

  attributes *(ATTRIBUTES + [:date_start, :date_end])
  attribute :has_time_start, delegate: :time_start
  attribute :has_time_end, delegate: :time_end
  # not for now:
  # :public_speaker, :location_type, :support_wanted,

  # actual not needed (wait for ui)
  # has_one :parent_event, class_name: 'Event', foreign_key: 'parent_id'
  # has_many :sub_events, class_name: 'Event', foreign_key: 'children_ids'

  # has_many :ownables, class_name: 'Ownable'
  has_one :orga

  before_create do
    @model.creator_id = context[:current_user].id
  end

  before_save do
    @model.last_editor_id = context[:current_user].id
  end

end
