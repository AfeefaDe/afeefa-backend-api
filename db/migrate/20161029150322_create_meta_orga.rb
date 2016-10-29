require File.join(__dir__, '..', 'seeds')

class CreateMetaOrga < ActiveRecord::Migration[5.0]
  def change
    Seeds.recreate_all
  end
end
