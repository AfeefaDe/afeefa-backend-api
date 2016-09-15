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

orga1 = Orga.create(title: 'Afeefa')
orga2 = Orga.create(title: 'Dresden für Alle e.V.')
orga3 = Orga.create(title: 'TU Dresden')


Role.create(user: user6, orga: orga1, title: Role::ORGA_ADMIN)
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


event1 = Event.create(title: 'Big Afeefa-Event')
event2 = Event.create(title: 'Kuefa im AZ-Conni')
event3 = Event.create(title: 'Playing Football')
event4 = Event.create(title: 'Cooking for All')

OwnerThingRelation.create(ownable: event1, thingable: orga1)
OwnerThingRelation.create(ownable: event2, thingable: user1)
OwnerThingRelation.create(ownable: event3, thingable: orga2)
OwnerThingRelation.create(ownable: event4, thingable: user1)