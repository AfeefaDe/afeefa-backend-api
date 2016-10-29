class Api::V1::EventResource < Api::V1::BaseResource
  attributes :title, :description, :created_at, :updated_at, :public_speaker, :location_type, :support_wanted, :active, :state, :date, :category

  has_one :parent_event, class_name: 'Event', foreign_key: 'parent_id'
  has_many :sub_events, class_name: 'Event', foreign_key: 'children_ids'

  #has_many :contact_infos
  filter :title, apply: ->(records, value, _options) {
    records.where('title like ?', value)
  }
end
