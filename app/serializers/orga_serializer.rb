class OrgaSerializer < BaseSerializer

  attributes :title, :description, :created_at, :updated_at

  belongs_to :parent, class_name: 'Orga'
  has_many :children, clas_name: 'Orga'

  has_many :users do
    link :related, "/api/v1/orgas/#{object.id}/users"
    include_data false
  end

  link :self do
    "/api/v1/orgas/#{object.id}"
  end
end
