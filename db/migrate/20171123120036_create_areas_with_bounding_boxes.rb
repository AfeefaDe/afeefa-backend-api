class CreateAreasWithBoundingBoxes < ActiveRecord::Migration[5.0]
  def up
    create_table :areas do |t|
      t.string :title
      t.string :lat_min
      t.string :lat_max
      t.string :lon_min
      t.string :lon_max

      t.timestamps null: false
    end
    add_index :areas, :title, unique: true

    Area.create!(title: 'dresden', lat_min: '50.811596', lat_max: '51.381457', lon_min: '12.983771', lon_max: '14.116620')
    Area.create!(title: 'leipzig', lat_min: '51.169806', lat_max: '51.455225', lon_min: '12.174588', lon_max: '12.659360')
    Area.create!(title: 'bautzen', lat_min: '51.001001', lat_max: '51.593835', lon_min: '13.710340', lon_max: '14.650444')
  end

  def down
    drop_table :areas
  end
end
