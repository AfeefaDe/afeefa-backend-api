class Api::V1::EventResource < Api::V1::BaseResource
  attributes :title, :description, :created_at, :updated_at, :public_speaker, :location_type, :support_wanted, :active, :state, :date

  has_one :parent_event, class_name: 'Event'
  has_many :children_event, clas_name: 'Event'

  #has_many :contact_infos

end
