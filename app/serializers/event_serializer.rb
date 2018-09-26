class EventSerializer
  include FastJsonapi::ObjectSerializer
  set_type :events

  attribute :title
  attribute :created_at, if: Proc.new { |record, params| !params[:public] == true }
  attribute :updated_at, if: Proc.new { |record, params| !params[:public] == true }
  attribute :active, if: Proc.new { |record, params| !params[:public] == true }
  attribute :date_start
  attribute :date_end
  attribute :has_time_start
  attribute :has_time_end

  has_many :facet_items, if: Proc.new { |record, params| params && params[:facet_items].present? }
  has_many :navigation_items, if: Proc.new { |record, params| params && params[:navigation_items].present? }
end
