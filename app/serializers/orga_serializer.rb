class OrgaSerializer
  include FastJsonapi::ObjectSerializer
  set_type :orgas
  attributes :title, :created_at, :updated_at, :active
  has_many :facet_items
  has_many :navigation_items
  has_many :annotations, if: Proc.new { |record, params| params && params[:annotations] == true }
end
