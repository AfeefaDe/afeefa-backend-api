class AddColorToFacet < ActiveRecord::Migration[5.0]
  def change
    add_column :facets, :color, :string, after: :title
    add_column :facets, :color_sub_items, :boolean, null: false, default: true, after: :color
  end
end
