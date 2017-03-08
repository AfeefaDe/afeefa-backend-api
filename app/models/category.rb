class Category < ApplicationRecord

  # ATTRIBUTES AND ASSOCIATIONS
  acts_as_tree(dependent: :restrict_with_exception)
  alias_method :sub_categories, :children
  alias_method :sub_categories=, :children=
  alias_method :parent_category, :parent
  alias_method :parent_category=, :parent=
  alias_attribute :parent_category_id, :parent_id

  scope :main_categories, -> { where(parent_id: nil) }
  scope :sub_categories, -> { where.not(parent_id: nil) }

end
