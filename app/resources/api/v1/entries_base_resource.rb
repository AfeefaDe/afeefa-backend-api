class Api::V1::EntriesBaseResource < Api::V1::BaseResource

  abstract

  ATTRIBUTES = [
    :title, :description, :created_at, :updated_at,
    :media_url, :media_type,
    :state_changed_at, :active]
  # define attributes in sub class like this:
  # attributes *ATTRIBUTES
  # or
  # attributes *(ATTRIBUTES + [:foo, :bar])

  has_many :annotations, class_name: 'Annotation'
  has_many :locations, class_name: 'Location'
  has_many :contact_infos, class_name: 'ContactInfo'

  has_one :category
  has_one :sub_category, class_name: 'Category'

  def active
    _model.state == StateMachine::ACTIVE.to_s
  end

  # paginator :offset

  # filter :todo, apply: ->(records, _value, _options) {
  #   records.annotated
  # }
  #
  # filter :title, apply: ->(records, value, _options) {
  #   records.where('title LIKE ?', "%#{value[0]}%")
  # }
  #
  # filter :description, apply: ->(records, value, _options) {
  #   records.where('description LIKE ?', "%#{value[0]}%")
  # }

end
