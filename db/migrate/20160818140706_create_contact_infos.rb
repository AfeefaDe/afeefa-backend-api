class CreateContactInfos < ActiveRecord::Migration
  def change
    create_table :contact_infos do |t|
      t.string :type
      t.string :content

      t.references :contactable, polymorphic: true, index: true
    end
  end
end
