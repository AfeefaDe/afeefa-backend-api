class AddUniqueIndexToActorRelations < ActiveRecord::Migration[5.0]
  def change
    add_index :actor_relations, [:associated_actor_id, :type]
    add_index :actor_relations, [:associating_actor_id, :type]
  end
end
