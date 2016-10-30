class Api::V1::EventResource < Api::V1::BaseResource

  attributes :title, :description, :created_at, :updated_at,
             :state_changed_at, :state, :state_transition,
             :category,
             # not for now:
             # :public_speaker, :location_type, :support_wanted,
             :date

  # actual not needed (wait for ui)
  # has_one :parent_event, class_name: 'Event', foreign_key: 'parent_id'
  # has_many :sub_events, class_name: 'Event', foreign_key: 'children_ids'

  has_many :annotations
  has_many :locations
  has_many :contact_infos

  # has_many :ownables, class_name: 'Ownable'
  has_one :orga

  has_one :creator, class_name: 'User'

  filter :title, apply: ->(records, value, _options) {
    records.where('title LIKE ? or description LIKE ?', "%#{value[0]}%", "%#{value[0]}%")
  }

  before_create do
    @model.creator_id = context[:current_user].id
  end

end
