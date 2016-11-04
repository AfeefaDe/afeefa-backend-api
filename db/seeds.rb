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

    # orgas
    if Orga.root_orga
      orga0 = Orga.root_orga
      orga0.title = Orga::ROOT_ORGA_TITLE
      orga0.save!(validate: false)
    else
      orga0 = Orga.create!(title: Orga::ROOT_ORGA_TITLE)
      orga0.save!(validate: false)
    end

    # users
    User.create!(email: 'felix@afeefa.de', forename: 'Felix', surname: 'Schönfeld', password: 'password5')
    User.create!(email: 'joschka@afeefa.de', forename: 'Joschka', surname: 'Heinrich', password: 'password2')
    User.create!(email: 'anna@afeefa.de', forename: 'Anna', surname: 'Neumann', password: 'password1')
    User.create!(email: 'steve@afeefa.de', forename: 'Steve', surname: 'Reinke', password: 'password1')
    User.create!(email: 'peter@afeefa.de', forename: 'Peter', surname: 'Hirsch', password: 'password3')

    # data for test and dev
    # if Rails.env.development?
    #   orga1 = orga0.sub_orgas.create!(
    #     title: 'Afeefa', description: 'Eine Beschreibung für Afeefa', category: 'welcome_ini')
    #   orga1.sub_orgas.create!(
    #     title: 'Integrations- und Ausländerbeauftragte', category: 'welcome_ini')
    #   orga1.sub_orgas.create!(
    #     title: 'Übersetzer Deutsch-Englisch-Französisch', state: 'inactive', category: 'welcome_ini')
    #   orga1.locations.create!(
    #     lat: '51.123456', lon: '17.123456',
    #     street: 'Diese komische Straße', number: '11abc',
    #     placename: 'äh, dort um die ecke',
    #     zip: '01309', city: 'Dresden',
    #     locatable: orga1)
    #   orga1.contact_infos.create!(
    #     mail: 'test@example.com',
    #     phone: '0123 -/ 456789',
    #     contact_person: 'Herr Max Müller',
    #     contactable: orga1)
    #   orga1.annotations.create!(title: 'Übersetzung fehlt')
    #
    #   orga2 = orga1.sub_orgas.create!(
    #     title: 'Dresden für Alle e.V.', description: 'Eine Beschreibung für Dresden für Alle e.V.',
    #     category: 'welcome_ini')
    #   orga2.locations.create!(
    #     lat: '51.123456', lon: '17.123456',
    #     street: 'Bischofsweg', number: '3',
    #     zip: '01307', city: 'Dresden')
    #   orga2.contact_infos.create!(
    #     mail: 'team@dresdenfueralle123.com',
    #     phone: '0123 -/ 456789',
    #     contact_person: 'Herr Max Mustermann')
    #   orga2.annotations.create!(title: 'Hier is was ganz kaputt...')
    #
    #   orga3 = orga1.sub_orgas.create!(
    #     title: 'TU Dresden', description: 'Eine Beschreibung für TU Dresden', category: 'welcome_ini')
    #   orga3.locations.create!(
    #     lat: '51.123456', lon: '17.123456',
    #     street: 'Zellescher Weg', number: '1',
    #     zip: '01307', city: 'Dresden')
    #   orga3.contact_infos.create!(
    #     mail: 'kontakt@tu-dd-0815.com',
    #     phone: '0123 -/ 456789',
    #     contact_person: 'Frau Frieda Blubb')
    #
    #   orga4 = orga1.sub_orgas.create!(title: 'Ausländerrat', state: 'inactive', category: 'welcome_ini')
    #   orga4.sub_orgas.create!(title: 'Interkultureller Frauentreff', category: 'welcome_ini', parent_orga: orga4, state: 'inactive')
    #   orga4.sub_orgas.create!(title: 'Außenstelle Adlergasse', category: 'welcome_ini', parent_orga: orga4, state: 'active')
    #   orga4.annotations.create!(title: 'foo bar')
    #
    #   orga5 = orga1.sub_orgas.create!(title: 'Frauentreff "Hand in Hand"', state: 'inactive', category: 'welcome_ini')
    #   orga5.annotations.create!(title: 'blablabla')
    #
    #   # users
    #   User.create!(email: 'benny@afeefa.de', forename: 'Benny', surname: 'Thomä', password: 'password4')
    #   user1 = User.create!(email: 'rudi@afeefa.de', forename: 'Rudi', surname: 'Dutschke', password: 'password1')
    #
    #   # events
    #   event1 = user1.created_events.create!(
    #     title: 'Big Afeefa-Event', state: 'active', category: 'community', orga: orga1)
    #   event1.locations.create!(
    #     lat: '51.123456', lon: '13.123456',
    #     street: 'Diese komische Straße', number: '11abc',
    #     placename: 'äh, dort um die ecke',
    #     zip: '01309', city: 'Dresden',
    #     locatable: orga1)
    #   event1.contact_infos.create!(
    #     mail: 'test@example.com',
    #     phone: '0123 -/ 456789',
    #     contact_person: 'Frau Max Müller',
    #     contactable: orga1)
    #   event1.annotations.create!(title: 'Übersetzung fehlerhaft')
    #   # OwnerThingRelation.create!(ownable: event1, thingable: orga1)
    #
    #   event2 = user1.created_events.create!(
    #     title: 'Kuefa im AZ-Conni', state: 'active', category: 'community', orga: orga1)
    #   event2.annotations.create!(title: 'Übersetzung zu stumpf')
    #   # OwnerThingRelation.create!(ownable: event2, thingable: user1)
    #
    #   event3 = user1.created_events.create!(
    #     title: 'Playing Football', state: 'active', category: 'community', orga: orga1)
    #   event3.annotations.create!(title: 'Ich frage mich, was das soll!?')
    #   # OwnerThingRelation.create!(ownable: event3, thingable: orga1)
    #
    #   event4 = user1.created_events.create!(
    #     title: 'Cooking for All', state: 'active', category: 'community', orga: orga1)
    #   # OwnerThingRelation.create!(ownable: event4, thingable: orga1)
    #
    #   event5 = user1.created_events.create!(
    #     title: 'Sommerfest', category: 'welcome_ini', parent_id: orga4, state: 'inactive', orga: orga2)
    #   # OwnerThingRelation.create!(ownable: user1.created_events5, thingable: orga1)
    #
    #   event6 = user1.created_events.create!(
    #     title: 'Deutschkurs', category: 'welcome_ini', parent_id: orga5, state: 'inactive', orga: orga2)
    #   # OwnerThingRelation.create!(ownable: event6, thingable: orga1)
    #
    #   event7 = user1.created_events.create!(
    #     title: 'Kulturtreff', category: 'welcome_ini', parent_id: orga5, state: 'inactive', creator: user1, orga: orga3)
    #   # OwnerThingRelation.create!(ownable: event7, thingable: orga2)
    #
    #   event8 = user1.created_events.create!(
    #     title: 'Offenes Netzwerktreffen Dresden für Alle',
    #     category: 'welcome_ini', parent_id: orga2, state: 'inactive', orga: orga4)
    #   # OwnerThingRelation.create!(ownable: event8, thingable: orga3)
    # end

    # Role.create!(user: user6, orga: orga1, title: Role::ORGA_ADMIN)
    # Role.create!(user: user7, orga: orga1, title: Role::ORGA_ADMIN)
    # Role.create!(user: user1, orga: orga1, title: Role::ORGA_MEMBER)
    # Role.create!(user: user2, orga: orga1, title: Role::ORGA_MEMBER)
    # Role.create!(user: user3, orga: orga1, title: Role::ORGA_MEMBER)
    # Role.create!(user: user4, orga: orga1, title: Role::ORGA_MEMBER)
    # Role.create!(user: user5, orga: orga1, title: Role::ORGA_MEMBER)
    #
    # Role.create!(user: user3, orga: orga2, title: Role::ORGA_ADMIN)
    # Role.create!(user: user1, orga: orga2, title: Role::ORGA_MEMBER)
    #
    # Role.create!(user: user4, orga: orga3, title: Role::ORGA_ADMIN)
    # Role.create!(user: user1, orga: orga3, title: Role::ORGA_MEMBER)
    # Role.create!(user: user3, orga: orga3, title: Role::ORGA_MEMBER)
    # Role.create!(user: user5, orga: orga3, title: Role::ORGA_MEMBER)
  end

  def self.marketentries_from_json(path: File.join(__dir__, '..', 'doc'), file: 'marketentries.json')
    json = JSON.parse(File.read(File.join(path, file)))
    marketentries = json['marketentries']

    # TODO: Einige Datensätze gibt es mehrfach (duplicate title):
    # pp marketentries.map{|x|x['name']}.sort

    marketentries.each do |orga|
      # TODO: Later we can use 'area' to set the geographically rights
      new_orga = Orga.new(
        title: orga['name'],
        description: orga['description'],
        category: orga['category']['name'],
        parent: Orga.root_orga
      )
      if new_orga.save
        # pp "Orga created: #{new_orga.id}, #{new_orga.title}"
      else
        pp 'Orga could not be created!'
        pp new_orga.title
        pp new_orga.errors.messages
        next
      end

      locations = orga['location']
      # if (count = locations.size) > 1
      #   pp "Orga #{orga.id} has #{count} locations but only the first could be migrated"
      # end
      # if location = locations.first
      if locations.each do |location|
        new_location = Location.new(
          locatable: new_orga,
          lat: location['lat'],
          lon: location['lon'],
          street: location['street'],
          number: 'Die Hausnummer steht aktuell in der Straße mit drin.',
          placename: location['placename'],
          zip: location['zip'],
          city: location['city'],
          district: location['district'],
          state: 'Sachsen',
          country: 'Deutschland',
        )
        if new_location.save
          # pp "Location for Orga #{new_orga.id} created: #{new_location.id}, #{new_location.street}"
        else
          pp 'Location could not be created!'
          pp new_location.street
          pp new_location.errors.messages
          next
        end
      end
      end
      new_contact_info = ContactInfo.new(
        contactable: new_orga,
        mail: json['mail'],
        phone: json['phone'],
        contact_person: json['speakerPublic']
      )
      if new_contact_info.save
        # pp "Location for Orga #{new_contact_info.id} created: #{new_contact_info.id}, #{new_contact_info.mail}"
      else
        pp 'Location could not be created!'
        pp new_contact_info.mail
        pp new_contact_info.errors.messages
        next
      end
    end
  end

end

Seeds.recreate_all
Seeds.marketentries_from_json
