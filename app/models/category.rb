class Category < ApplicationRecord

  acts_as_tree(dependent: :restrict_with_exception)
  alias_method :sub_categories, :children
  alias_method :parent_category, :parent
  alias_method :parent_category=, :parent=
  alias_method :sub_categories=, :children=

  has_and_belongs_to_many :orgas, join_table: 'orga_category_relations'

  has_many :thing_category_relations
  has_many :events, through: :thing_category_relations, source: :catable, source_type: 'Event'

end
