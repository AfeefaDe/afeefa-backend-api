class CreateOrgaTypes < ActiveRecord::Migration[5.0]
  def up
    create_table :orga_types do |t|
      t.string :name
      t.timestamps
    end

    OrgaType.create!(name: 'Root')
    OrgaType.create!(name: 'Organization')
    OrgaType.create!(name: 'Project')
    OrgaType.create!(name: 'Offer')
    OrgaType.create!(name: 'Location')
    OrgaType.create!(name: 'Network')
    OrgaType.create!(name: 'Department')

    add_reference :orgas, :orga_type, references: :orga_types, index: true, after: :id

    Orga.unscoped.all.each do |orga|
      if orga.id == 1
        orga.orga_type_id = OrgaType.where(name: 'Root').first['id']
      else
        if orga.parent_orga_id != 1
          orga.orga_type_id = OrgaType.where(name: 'Project').first['id']
        else
          orga.orga_type_id = OrgaType.where(name: 'Organization').first['id']
        end
      end
      orga.save(validate: false)
    end
  end

  def down
    drop_table :orga_types

    remove_reference(:orgas, :orga_type, index: true)
  end
end
