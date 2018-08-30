class OrgaSerializer
  include FastJsonapi::ObjectSerializer
  set_type :orgas
  attributes :title, :created_at, :updated_at, :active
  has_many :facet_items, if: Proc.new { |record, params| params && params[:facet_items].present? }
  has_many :navigation_items, if: Proc.new { |record, params| params && params[:navigation_items].present? }
end
