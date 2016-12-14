class Category < ApplicationRecord

  scope :main_categories, -> { where(is_sub_category: false) }
  scope :sub_categories, -> { where(is_sub_category: true) }

end
