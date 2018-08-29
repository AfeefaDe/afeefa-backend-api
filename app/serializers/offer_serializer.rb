class OfferSerializer
  include FastJsonapi::ObjectSerializer
  set_type :offers
  attributes :title
  has_many :facet_items
  has_many :navigation_items
  has_many :annotations, if: Proc.new { |record, params| params && params[:annotations] == true }
end
