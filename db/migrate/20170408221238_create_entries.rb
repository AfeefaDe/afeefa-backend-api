class CreateEntries < ActiveRecord::Migration[5.0]
  def change
    create_table :entries do |t|
      t.references :entry, polymorphic: true, index: true
    end
  end
end
