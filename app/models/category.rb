class Category < ApplicationRecord

  include Jsonable

  # ATTRIBUTES AND ASSOCIATIONS
  acts_as_tree(dependent: :restrict_with_exception)
  alias_method :sub_categories, :children
  alias_method :sub_categories=, :children=
  alias_method :parent_category, :parent
  alias_method :parent_category=, :parent=
  alias_attribute :parent_category_id, :parent_id

  scope :main_categories, -> { where(parent_id: nil) }
  scope :sub_categories, -> { where.not(parent_id: nil) }

  private

  def relationships_for_json
    {
      parent_category: { data: parent_category.try(:to_hash, only_reference: true) },
    }
  end

  def short_relationships_for_json
    relationships_for_json
  end
end
