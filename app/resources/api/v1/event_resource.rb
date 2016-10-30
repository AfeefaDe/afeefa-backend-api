class Api::V1::EventResource < Api::V1::BaseResource

  attributes :title, :description, :created_at, :updated_at,
             :state_changed_at, :state, :state_transition,
             :category,
             :public_speaker, :location_type, :support_wanted,
             :date

  # actual not needed (wait for ui)
  # has_one :parent_event, class_name: 'Event', foreign_key: 'parent_id'
  # has_many :sub_events, class_name: 'Event', foreign_key: 'children_ids'

  has_one :annotation
  has_one :location
  has_one :contact_info

  # has_many :ownables, class_name: 'Ownable'
  has_many :orgas, class_name: 'Orga'

  has_one :creator, class_name: 'User'

  filter :title, apply: ->(records, value, _options) {
    records.where('title LIKE ? or description LIKE ?', "%#{value[0]}%", "%#{value[0]}%")
  }

end
