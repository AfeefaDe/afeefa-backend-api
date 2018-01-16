# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create!([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create!(name: 'Luke', movie: movies.first)

module Seeds

  def self.recreate_all
    # clean up
    Orga.without_root.delete_all

    unless Rails.env.production?
      User.delete_all
    end

    Event.delete_all
    Entry.delete_all

    Location.delete_all
    ContactInfo.delete_all

    AnnotationCategory.delete_all
    Annotation.delete_all

    Category.delete_all

    # categories and sub categories
    Neos::Migration::SUB_CATEGORIES.each do |main_category, categories|
      unless new_main_category = Category.find_by_title(main_category)
        new_main_category =
          Category.create!(title: main_category)
      end

      categories.each do |category|
        Category.create!(title: category[:name], parent_id: new_main_category.id)
      end
    end

    # orga types
    OrgaType.delete_all
    OrgaType.create!(name: 'Root')
    OrgaType.create!(name: 'Organization')
    OrgaType.create!(name: 'Project')
    OrgaType.create!(name: 'Offer')
    OrgaType.create!(name: 'Location')
    OrgaType.create!(name: 'Network')
    OrgaType.create!(name: 'Department')

    # orgas
    if Orga.root_orga
      orga0 = Orga.root_orga
      orga0.orga_type_id = OrgaType.where(name: 'Root').first['id']
      orga0.title = Orga::ROOT_ORGA_TITLE
      orga0.description = Orga::ROOT_ORGA_DESCRIPTION
      orga0.save!(validate: false)
    else
      orga0 = Orga.new(title: Orga::ROOT_ORGA_TITLE, description: Orga::ROOT_ORGA_DESCRIPTION)
      orga0.orga_type_id = OrgaType.where(name: 'Root').first['id']
      orga0.save!(validate: false)
    end

    # users
    unless Rails.env.production?
      User.create!(email: 'anna@afeefa.de', forename: 'Anna', surname: 'Neumann', password: 'MapCat_050615')
      User.create!(email: 'felix@afeefa.de', forename: 'Felix', surname: 'Schönfeld', password: 'MapCat_050615')
      User.create!(email: 'joschka@afeefa.de', forename: 'Joschka', surname: 'Heinrich', password: 'MapCat_050615')
      User.create!(email: 'steve@afeefa.de', forename: 'Steve', surname: 'Reinke', password: 'MapCat_050615')
      User.create!(email: 'peter@afeefa.de', forename: 'Peter', surname: 'Hirsch', password: 'MapCat_050615')
      User.create!(email: 'alex@afeefa.de', forename: 'Alex', surname: 'Weiß', password: 'MapCat_050615')
      User.create!(email: 'friedrich@afeefa.de', forename: 'Friedrich', surname: 'Weise', password: 'MapCat_050615')
      User.create!(email: 'hagen@afeefa.de', forename: 'Hagen', surname: 'Belitz', password: 'MapCat_050615')
    end

    # annotations
    AnnotationCategory.create!(title: 'Titel ist zu lang', generated_by_system: true)
    AnnotationCategory.create!(title: 'Titel ist bereits vergeben', generated_by_system: true)
    AnnotationCategory.create!(title: 'Kurzbeschreibung ist zu lang', generated_by_system: true)
    AnnotationCategory.create!(title: 'Kurzbeschreibung fehlt', generated_by_system: true)
    AnnotationCategory.create!(title: 'Hauptkategorie fehlt', generated_by_system: true)
    AnnotationCategory.create!(title: 'Start-Datum fehlt', generated_by_system: true)

    AnnotationCategory.create!(title: 'Kontaktdaten', generated_by_system: false)
    AnnotationCategory.create!(title: 'Ort', generated_by_system: false)
    AnnotationCategory.create!(title: 'Beschreibung', generated_by_system: false)
    AnnotationCategory.create!(title: 'Bild', generated_by_system: false)
    AnnotationCategory.create!(title: 'Kategorie', generated_by_system: false)
    AnnotationCategory.create!(title: 'Zugehörigkeit', generated_by_system: false)

    AnnotationCategory.create!(title: 'Sonstiges', generated_by_system: false)

    AnnotationCategory.create!(title: 'Externe Eintragung', generated_by_system: true)

    AnnotationCategory.create!(title: 'ENTWURF', generated_by_system: false)
    AnnotationCategory.create!(title: 'DRINGEND', generated_by_system: false)

    # TODO: Validierung einbauen und Migration handlen!
    AnnotationCategory.create!(title: 'Unterkategorie passt nicht zur Hauptkategorie',
      generated_by_system: true)

    # nice to have (for maintenance views):
    # accessible media_url and correct media_type for entry
    # no phone nor mail in contact_info
  end

end

pp "Start seeding database (#{Time.current.to_s})."
Seeds.recreate_all
pp "Seeding database finished (#{Time.current.to_s})."
unless Rails.env.test?
  begin
    Neos::Migration.
      migrate(
        migrate_phraseapp: (Settings.phraseapp.active rescue false),
        limit: {
          orgas: Settings.try(:migration).try(:limit).try(:orgas),
          events: Settings.try(:migration).try(:limit).try(:events) })
  rescue ActiveRecord::NoDatabaseError => _exception
    pp 'Migration of live db data could not be processed because the db configured in database.yml ' +
      'could not be found. Is db connection \'afeefa\' defined correctly? ' +
      'And did you import the db dump from repository?'
  rescue ActiveRecord::AdapterNotSpecified => _exception
    pp 'Migration of live db data could not be processed because no db is configured in database.yml. ' +
      'Is db connection \'afeefa\' defined correctly? ' +
      'And did you import the db dump from repository?'
  end
end
# TODO: Discuss user logins for production!
