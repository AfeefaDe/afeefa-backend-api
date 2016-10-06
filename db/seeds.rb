# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
user1 = User.create(email: 'rudi@afeefa.de', forename: 'Rudi', surname: 'Dutschke', password: 'password1')
user2 = User.create(email: 'steve@afeefa.de', forename: 'Steve', surname: 'Reinke', password: 'password1')
user3 = User.create(email: 'joschka@afeefa.de', forename: 'Joschka', surname: 'Heinrich', password: 'password2')
user4 = User.create(email: 'peter@afeefa.de', forename: 'Peter', surname: 'Hirsch', password: 'password3')
user5 = User.create(email: 'benny@afeefa.de', forename: 'Benny', surname: 'Thomä', password: 'password4')
user6 = User.create(email: 'felix@afeefa.de', forename: 'Felix', surname: 'Schönfeld', password: 'password5')
user7 = User.create(email: 'anna@afeefa.de', forename: 'Anna', surname: 'Neumann', password: 'password1')

orga1 = Orga.create(title: 'Afeefa', description: 'Eine Beschreibung für Afeefa')
orga2 = Orga.create(title: 'Dresden für Alle e.V.', description: 'Eine Beschreibung für Dresden für Alle e.V.')
orga3 = Orga.create(title: 'TU Dresden', description: 'Eine Beschreibung für TU Dresden')
orga4 = Orga.create(title: 'Ausländerrat', state: 'edit_request')
orga5 = Orga.create(title: 'Frauentreff "Hand in Hand"', state: 'edit_request')
orga6 = Orga.create(title: 'Integrations- und Ausländerbeauftragte')
orga7 = Orga.create(title: 'Übersetzer Deutsch-Englisch-Französisch', state: 'edit_request')
suborga1 = Orga.create(title: 'Interkultureller Frauentreff', parent_orga: orga4, state: 'new')
suborga2 = Orga.create(title: 'Außenstelle Adlergasse', parent_orga: orga4, state: 'new')


Role.create(user: user6, orga: orga1, title: Role::ORGA_ADMIN)
Role.create(user: user7, orga: orga1, title: Role::ORGA_ADMIN)
Role.create(user: user1, orga: orga1, title: Role::ORGA_MEMBER)
Role.create(user: user2, orga: orga1, title: Role::ORGA_MEMBER)
Role.create(user: user3, orga: orga1, title: Role::ORGA_MEMBER)
Role.create(user: user4, orga: orga1, title: Role::ORGA_MEMBER)
Role.create(user: user5, orga: orga1, title: Role::ORGA_MEMBER)

Role.create(user: user3, orga: orga2, title: Role::ORGA_ADMIN)
Role.create(user: user1, orga: orga2, title: Role::ORGA_MEMBER)

Role.create(user: user4, orga: orga3, title: Role::ORGA_ADMIN)
Role.create(user: user1, orga: orga3, title: Role::ORGA_MEMBER)
Role.create(user: user3, orga: orga3, title: Role::ORGA_MEMBER)
Role.create(user: user5, orga: orga3, title: Role::ORGA_MEMBER)


event1 = Event.create(title: 'Big Afeefa-Event', state: 'new')
event2 = Event.create(title: 'Kuefa im AZ-Conni', state: 'new')
event3 = Event.create(title: 'Playing Football', state: 'active')
event4 = Event.create(title: 'Cooking for All', state: 'active')
event5 = Event.create(title: 'Sommerfest', parent_id: orga4, state: 'annotated')
event6 = Event.create(title: 'Deutschkurs', parent_id: orga5, state: 'annotated')
event7 = Event.create(title: 'Kulturtreff', parent_id: orga5, state: 'inactive')
event8 = Event.create(title: 'Offenes Netzwerktreffen Dresden für Alle', parent_id: orga2, state: 'inactive')

OwnerThingRelation.create(ownable: event1, thingable: orga1)
OwnerThingRelation.create(ownable: event2, thingable: user1)
OwnerThingRelation.create(ownable: event3, thingable: orga1)
OwnerThingRelation.create(ownable: event4, thingable: orga1)
OwnerThingRelation.create(ownable: event5, thingable: orga1)
OwnerThingRelation.create(ownable: event6, thingable: orga1)
OwnerThingRelation.create(ownable: event7, thingable: orga2)
OwnerThingRelation.create(ownable: event8, thingable: orga3)