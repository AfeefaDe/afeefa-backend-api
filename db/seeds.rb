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
    User.delete_all
    Event.delete_all

    Location.delete_all
    ContactInfo.delete_all

    Annotation.delete_all

    # sub categories
    Able::SUB_CATEGORIES.each do |category|
      Category.create!(
        title: category,
        is_sub_category: true
      )
    end

    # orgas
    if Orga.root_orga
      orga0 = Orga.root_orga
      orga0.title = Orga::ROOT_ORGA_TITLE
      orga0.save!(validate: false)
    else
      orga0 = Orga.new(title: Orga::ROOT_ORGA_TITLE)
      orga0.save!(validate: false)
    end

    # users
    User.create!(email: 'anna@afeefa.de', forename: 'Anna', surname: 'Neumann', password: 'password1')
    User.create!(email: 'felix@afeefa.de', forename: 'Felix', surname: 'Schönfeld', password: 'password5')
    User.create!(email: 'joschka@afeefa.de', forename: 'Joschka', surname: 'Heinrich', password: 'password2')
    User.create!(email: 'steve@afeefa.de', forename: 'Steve', surname: 'Reinke', password: 'password1')
    User.create!(email: 'peter@afeefa.de', forename: 'Peter', surname: 'Hirsch', password: 'password3')
    User.create!(email: 'alex@afeefa.de', forename: 'Alex', surname: 'Weiß', password: 'password1')
    User.create!(email: 'friedrich@afeefa.de', forename: 'Friedrich', surname: 'Weise', password: 'password1')
  end

end

Seeds.recreate_all
unless Rails.env.test?
  begin
    Neos::Migration.migrate
  rescue ActiveRecord::NoDatabaseError => _exception
    pp %q(Migration of live db data could not be processed because the db configured in database.yml could not be found. Is db connection 'afeefa' defined correctly? And did you import the db dump from repository?)
  rescue ActiveRecord::AdapterNotSpecified => _exception
    pp %q(Migration of live db data could not be processed because no db is configured in database.yml. Is db connection 'afeefa' defined correctly? And did you import the db dump from repository?)
  end
end
# TODO: Discuss user logins for production!
