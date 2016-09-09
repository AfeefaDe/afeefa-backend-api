class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.string :title
      t.references :user, index: true
      t.references :organization, index: true

      t.timestamps null: false
    end
  end
end
