class Api::V1::EntriesBaseResource < Api::V1::BaseResource

  abstract

  ATTRIBUTES = [
    :title, :description, :short_description, :created_at, :updated_at,
    :media_url, :media_type, :support_wanted, :support_wanted_detail,
    :certified_sfr, :tags,
    :creator_id, :last_editor_id,
    :state_changed_at, :active, :inheritance]
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

end
