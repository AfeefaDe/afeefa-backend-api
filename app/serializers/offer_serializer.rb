class OfferSerializer
  include FastJsonapi::ObjectSerializer
  set_type :offers

  attribute :title
  attribute :created_at, if: Proc.new { |record, params| !params[:public] == true }
  attribute :updated_at, if: Proc.new { |record, params| !params[:public] == true }
  attribute :active, if: Proc.new { |record, params| !params[:public] == true }

  has_many :facet_items, if: Proc.new { |record, params| params && params[:facet_items].present? }
  has_many :navigation_items, if: Proc.new { |record, params| params && params[:navigation_items].present? }
end
