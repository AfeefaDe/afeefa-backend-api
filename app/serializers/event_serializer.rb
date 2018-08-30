class EventSerializer
  include FastJsonapi::ObjectSerializer
  set_type :events
  attributes :title, :active, :created_at, :updated_at, :date_start, :date_end, :time_start, :time_end
  has_many :facet_items, if: Proc.new { |record, params| params && params[:facet_items].present? }
  has_many :navigation_items, if: Proc.new { |record, params| params && params[:navigation_items].present? }
end
