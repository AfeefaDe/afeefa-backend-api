class CreateActorRelations < ActiveRecord::Migration[5.0]

  def up
    create_table :actor_relations do |t|
      t.references :associating_actor, index: true
      t.references :associated_actor, index: true
      t.string :type, index: true
      t.timestamps
    end

    Orga.all.select { |orga| orga.sub_orgas.present? }.each do |orga|
      orga.sub_orgas.each do |sub_orga|
        DataModules::Actor::ActorRelation.create!(
          associating_actor: Orga.find(orga.id),
          associated_actor: Orga.find(sub_orga.id),
          type: DataModules::Actor::ActorRelation::PROJECT)
      end
    end
  end

  def down
    drop_table :actor_relations
  end
end
