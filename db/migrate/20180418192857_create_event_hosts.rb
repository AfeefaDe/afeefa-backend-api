class CreateEventHosts < ActiveRecord::Migration[5.0]
  def up
    create_table :event_hosts do |t|
      t.references :actor, index: true
      t.references :event, index: true

      t.timestamps
    end

    Event.all.each do |event|
      if event.orga_id != Orga.root_orga.id
        host = EventHost.create(
          actor_id: event.orga.id,
          event_id: event.id
        )
      end
    end

  end

  def down
    drop_table :event_hosts
  end
end
