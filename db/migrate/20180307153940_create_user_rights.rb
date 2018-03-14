class CreateUserRights < ActiveRecord::Migration[5.0]
  def change
    create_table :user_rights do |t|
      t.references :user
      t.references :object, polymorphic: true
      t.string :caption

      t.timestamps
    end
  end
end
