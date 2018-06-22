class AddMainClassificationToFacetOwnerType < ActiveRecord::Migration[5.0]
  def change
    add_column :facet_owner_types, :main_facet, :boolean, null: false, default: false

    DataPlugins::Facet::FacetOwnerType.reset_column_information

    DataPlugins::Facet::FacetOwnerType.
        where(owner_type: 'Orga').
        order('id').
        first.
        update(
          main_facet: true
        )

    DataPlugins::Facet::FacetOwnerType.
        where(owner_type: 'Offer').
        order('id').
        first.
        update(
          main_facet: true
        )

    DataPlugins::Facet::FacetOwnerType.
        where(owner_type: 'Event').
        order('id').
        last.
        update(
          main_facet: true
        )
  end
end
