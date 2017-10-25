class AddAttachmentImageToResources < ActiveRecord::Migration
  def self.up
    change_table :resources do |t|
      t.attachment :image
    end
  end

  def self.down
    remove_attachment :resources, :image
  end
end
