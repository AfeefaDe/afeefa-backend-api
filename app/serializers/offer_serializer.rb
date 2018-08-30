class OfferSerializer
  include FastJsonapi::ObjectSerializer
  set_type :offers
  attributes :title, :active, :created_at, :updated_at
  has_many :facet_items, if: Proc.new { |record, params| params && params[:facet_items].present? }
  has_many :navigation_items, if: Proc.new { |record, params| params && params[:navigation_items].present? }
end
