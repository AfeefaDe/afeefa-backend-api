class Api::V1::CategoryResource < Api::V1::BaseResource

  attributes :title, :is_sub_category

  filter :title, apply: ->(records, value, _options) {
    records.where('title LIKE ?', "%#{value[0]}%")
  }

  filter :is_sub_category, apply: ->(records, value, _options) {
    records.where('is_sub_category LIKE ?', "%#{value[0]}%")
  }

end
