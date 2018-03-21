class Category < ApplicationRecord

  include Jsonable

  # ATTRIBUTES AND ASSOCIATIONS
  acts_as_tree(dependent: :restrict_with_exception)
  alias_method :sub_categories, :children
  alias_method :sub_categories=, :children=
  alias_method :parent_category, :parent
  alias_method :parent_category=, :parent=
  alias_attribute :parent_category_id, :parent_id

  has_many :events
  has_many :orgas
  has_many :events_as_subcategory, class_name: 'Event', foreign_key: 'sub_category_id'
  has_many :orgas_as_subcategory, class_name: 'Orga', foreign_key: 'sub_category_id'

  def owners
    events + events_as_subcategory + orgas + orgas_as_subcategory
  end

  scope :main_categories, -> { where(parent_id: nil) }
  scope :sub_categories, -> { where.not(parent_id: nil) }
  scope :by_area, ->(area) { where(area: area) }

  # CLASS METHODS
  class << self
    def attribute_whitelist_for_json
      default_attributes_for_json.freeze
    end

    def default_attributes_for_json
      %i(title count_owners).freeze
    end

    def relation_whitelist_for_json
      default_relations_for_json
    end

    def default_relations_for_json
      %i(parent_category).freeze
    end

    def count_relation_whitelist_for_json
      %i(owners).freeze
    end
end

end
