class Api::V1::TodoResource < Api::V1::BaseResource

  immutable
  abstract

  has_many :orgas
  has_many :events

  def self.records(options = {})
    TodoList.new
  end

  def self.apply_filter(records, filter, value, options)
    records
  end

  def self.apply_sort(records, order_options, context = {})
    records
  end

end
