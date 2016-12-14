class Api::V1::EventResource < Api::V1::BaseResource

  attributes :title, :description, :created_at, :updated_at,
             :state_changed_at, :state, :state_transition,
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

  has_one :category
  has_one :sub_category, class_name: 'Category'

  before_create do
    @model.creator_id = context[:current_user].id
  end

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
