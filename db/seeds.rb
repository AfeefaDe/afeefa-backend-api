# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create!([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create!(name: 'Luke', movie: movies.first)

module Seeds

  def self.recreate_all
    Settings.afeefa.fapi_sync_active = false

    pp "Start seeding database (#{Time.current.to_s})."

    # clean up

    pp 'delete events, orgas and entries'

    Orga.without_root.delete_all
    Event.delete_all
    Entry.delete_all

    pp 'delete and create areas'

    # areas
    # TODO: Do we need this any longer?
    Area.delete_all
    Area.create!(title: 'dresden', lat_min: '50.811596', lat_max: '51.381457', lon_min: '12.983771', lon_max: '14.116620')
    Area.create!(title: 'leipzig', lat_min: '51.169806', lat_max: '51.455225', lon_min: '12.174588', lon_max: '12.659360')
    Area.create!(title: 'bautzen', lat_min: '51.001001', lat_max: '51.593835', lon_min: '13.710340', lon_max: '14.650444')

    pp 'delete and create orga types'

    # orga types
    OrgaType.delete_all
    OrgaType.create!(name: 'Root')
    OrgaType.create!(name: 'Organization')
    OrgaType.create!(name: 'Project')
    OrgaType.create!(name: 'Location')
    OrgaType.create!(name: 'Network')

    pp 'create orgas'

    # orgas
    if Orga.root_orga
      orga0 = Orga.root_orga
      orga0.orga_type_id = OrgaType.where(name: 'Root').first['id']
      orga0.title = Orga::ROOT_ORGA_TITLE
      orga0.description = Orga::ROOT_ORGA_DESCRIPTION
      orga0.area = 'dresden'
      orga0.save!(validate: false)
    else
      orga0 = Orga.new(title: Orga::ROOT_ORGA_TITLE, description: Orga::ROOT_ORGA_DESCRIPTION, area: 'dresden')
      orga0.orga_type_id = OrgaType.where(name: 'Root').first['id']
      orga0.save!(validate: false)
    end

    pp 'delete and create users'

    unless Rails.env.production?
      User.delete_all
    end

    # users
    unless Rails.env.production?
      User.create!(email: 'anna@afeefa.de', forename: 'Anna', surname: 'Neumann', password: 'MapCat_050615')
    end

    pp 'delete and create annotations'

    AnnotationCategory.delete_all
    Annotation.delete_all

    # annotations
    AnnotationCategory.create!(title: 'Kurzbeschreibung fehlt', generated_by_system: true)
    AnnotationCategory.create!(title: 'Kontaktdaten', generated_by_system: false)

    pp "Seeding database finished (#{Time.current.to_s})."
  end

end
