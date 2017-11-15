class AddCreatorToOrgas < ActiveRecord::Migration[5.0]

  def change
    add_reference :orgas, :creator, references: :users, index: true
  end

end
