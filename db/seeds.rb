# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create!([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create!(name: 'Luke', movie: movies.first)

module Seeds

  def self.recreate_all(cleanup_phraseapp: Settings.phraseapp.active || false)
    # clean up
    Orga.without_root.delete_all
    User.delete_all
    Event.delete_all
    Entry.delete_all

    Location.delete_all
    ContactInfo.delete_all

    Annotation.delete_all
    Todo.delete_all

    Category.delete_all

    if cleanup_phraseapp
      delete_count = (@client ||= PhraseAppClient.new).send(:delete_all_keys)
      pp "Cleaned up phraseapp. Deleted #{delete_count} keys."
    end

    # categories and sub categories
    Able::SUB_CATEGORIES.each do |main_category, categories|
      unless new_main_category = Category.find_by_title(main_category)
        new_main_category =
          Category.create!(title: main_category)
      end

      categories.each do |category|
        Category.create!(title: category[:name], parent_id: new_main_category.id)
      end
    end

    # orgas
    if Orga.root_orga
      orga0 = Orga.root_orga
      orga0.title = Orga::ROOT_ORGA_TITLE
      orga0.description = Orga::ROOT_ORGA_DESCRIPTION
      orga0.save!(validate: false)
    else
      orga0 = Orga.new(title: Orga::ROOT_ORGA_TITLE, description: Orga::ROOT_ORGA_DESCRIPTION)
      orga0.save!(validate: false)
    end

    # users
    User.create!(email: 'anna@afeefa.de', forename: 'Anna', surname: 'Neumann', password: 'MapCat_050615')
    User.create!(email: 'felix@afeefa.de', forename: 'Felix', surname: 'Schönfeld', password: 'MapCat_050615')
    User.create!(email: 'joschka@afeefa.de', forename: 'Joschka', surname: 'Heinrich', password: 'MapCat_050615')
    User.create!(email: 'steve@afeefa.de', forename: 'Steve', surname: 'Reinke', password: 'MapCat_050615')
    User.create!(email: 'peter@afeefa.de', forename: 'Peter', surname: 'Hirsch', password: 'MapCat_050615')
    User.create!(email: 'alex@afeefa.de', forename: 'Alex', surname: 'Weiß', password: 'MapCat_050615')
    User.create!(email: 'friedrich@afeefa.de', forename: 'Friedrich', surname: 'Weise', password: 'MapCat_050615')
    User.create!(email: 'hagen@afeefa.de', forename: 'Hagen', surname: 'Belitz', password: 'MapCat_050615')

    # annotations
    Annotation.create!(title: 'Eintrag fehlerhaft')
    Annotation.create!(title: 'Eintrag gemeldet')
    Annotation.create!(title: 'Übersetzung fehlt')
    # Be careful with changes, replace usages this annotation title!
    Annotation.create!(title: 'Migration nur teilweise erfolgreich')
  end

end

pp "Start seeding database (#{Time.current.to_s})."
Seeds.recreate_all(cleanup_phraseapp: Settings.phraseapp.active || false)
pp "Seeding database finished (#{Time.current.to_s})."
unless Rails.env.test?
  begin
    Neos::Migration.migrate(migrate_phraseapp: Settings.phraseapp.active || false, limit: { orgas: nil, events: nil })
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
