class AddOrgaIdToEvents < ActiveRecord::Migration[5.0]
  def change
    add_reference :events, :orga, index: true
  end
end
