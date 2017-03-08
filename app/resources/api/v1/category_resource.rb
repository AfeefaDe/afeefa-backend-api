class Api::V1::CategoryResource < Api::V1::BaseResource

  model_name 'Category'

  attributes :title

  has_one :parent_category, class_name: 'Category', foreign_key: 'parent_id'

end
