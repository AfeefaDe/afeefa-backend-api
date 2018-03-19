require 'test_helper'

module DataPlugins::Contact
  class ContactTest < ActiveSupport::TestCase

    should 'create contact with own location' do
      contact = nil
      orga = create(:orga)

      assert_difference -> { DataPlugins::Contact::Contact.count } do
        assert_difference -> { DataPlugins::Contact::ContactPerson.count }, 2 do
          assert_difference -> { DataPlugins::Location::Location.count } do
            contact = save_contact(orga, { action: 'create', owner_id: orga.id, owner_type: 'orgas' }.merge(
              parse_json_file(file: 'contact_with_location.json')
            ))
          end
        end
      end

      assert_equal 'Titel des Kontaktes', contact.title
      assert_equal orga, contact.owner

      location = contact.location
      assert_equal contact, location.contact
      assert_equal orga, location.owner
      assert_equal 'New Location', location.title

      contact_persons = contact.contact_persons
      assert_equal 'Hansi', contact_persons[0].name
      assert_equal 'Claudia Schantall', contact_persons[1].name
    end

    should 'create contact with linked location' do
      contact = nil
      orga = create(:orga)

      contact2 = create(:contact)
      orga2 = create(:another_orga)
      location = create(:afeefa_office, contact: contact2, owner: orga2)

      assert_difference -> { DataPlugins::Contact::Contact.count } do
        assert_difference -> { DataPlugins::Contact::ContactPerson.count }, 2 do
          assert_no_difference -> { DataPlugins::Location::Location.count } do
            contact = save_contact(orga, { action: 'create', owner_id: orga.id, owner_type: 'orgas' }.merge(
              parse_json_file(file: 'contact_with_location_id.json') do |payload|
                payload.gsub!('<location_id>', location.id.to_s)
              end
            ))
          end
        end
      end

      assert_equal orga, contact.owner

      location = contact.location
      assert_equal contact2, location.contact
      assert_equal orga2, location.owner
      assert_equal 'Afeefa Büro', location.title
    end

    should 'update (contact with own location) with own location' do
      orga = create(:orga)
      location = create(:afeefa_office, owner: orga)
      id = location.id
      contact = create(:contact, owner: orga, location: location)
      location.update(contact: contact)

      assert_equal orga, contact.owner
      assert_equal location, contact.location
      assert_equal 'Bayrische Str.8', location.street
      assert_equal orga, location.owner
      assert_equal contact, location.contact

      assert_no_difference -> { DataPlugins::Location::Location.count } do
        save_contact(orga, {action: 'update', id: contact.id, location: {
          title: 'Neues Büro'
        }})
      end

      location.reload

      assert_equal orga, contact.owner
      assert_equal location, contact.location
      assert_equal id, location.id
      assert_equal 'Neues Büro', location.title
      assert_equal 'Bayrische Str.8', location.street

      assert_equal orga, location.owner
      assert_equal contact, location.contact
    end

    should 'update (contact with own location) with linked location and delete own location' do
      orga = create(:orga)
      location = create(:afeefa_office, owner: orga)
      contact = create(:contact, owner: orga, location: location)
      location.update(contact: contact)

      orga2 = create(:another_orga)
      contact2 = create(:contact)
      location2 = create(:afeefa_montagscafe, contact: contact2, owner: orga2)

      assert_equal orga, contact.owner
      assert_equal location, contact.location
      assert_equal 'Bayrische Str.8', location.street
      assert_equal orga, location.owner
      assert_equal contact, location.contact

      assert_difference -> { DataPlugins::Location::Location.count }, -1 do
        save_contact(orga, {action: 'update', id: contact.id, location_id: location2.id})
      end

      contact.reload

      assert_equal orga, contact.owner
      assert_equal location2, contact.location
      assert_equal 'Afeefa im Montagscafé', contact.location.title
      assert_equal orga2, contact.location.owner
      assert_equal contact2, contact.location.contact
    end

    should 'update (contact with linked location) with linked location' do
      orga2 = create(:another_orga)
      contact2 = create(:contact)
      location2 = create(:afeefa_office, contact: contact2, owner: orga2)

      orga = create(:orga)
      contact = create(:contact, owner: orga, location: location2)

      contact3 = create(:contact)
      location3 = create(:afeefa_montagscafe, contact: contact3, owner: orga2)

      assert_equal orga, contact.owner
      assert_equal location2, contact.location
      assert_equal orga2, contact.location.owner
      assert_equal contact2, contact.location.contact

      assert_no_difference -> { DataPlugins::Location::Location.count } do
        save_contact(orga, {action: 'update', id: contact.id, location_id: location3.id})
      end

      contact.reload

      assert_equal orga, contact.owner
      assert_equal location3, contact.location
      assert_equal 'Afeefa im Montagscafé', contact.location.title
      assert_equal orga2, contact.location.owner
      assert_equal contact3, contact.location.contact
    end

    private

    def save_contact(orga, hash)
      orga.save_contact(ActionController::Parameters.new(hash))
    end

    should 'update (contact with linked location) with own location' do
      orga2 = create(:another_orga)
      contact2 = create(:contact)
      location2 = create(:afeefa_office, contact: contact2, owner: orga2)

      orga = create(:orga)
      contact = create(:contact, owner: orga, location: location2)

      assert_equal orga, contact.owner
      assert_equal location2, contact.location
      assert_equal orga2, contact.location.owner
      assert_equal contact2, contact.location.contact

      assert_difference -> { DataPlugins::Location::Location.count } do
        save_contact(orga, {action: 'update', id: contact.id, location: {
          title: 'Neues Büro'
        }})
      end

      contact.reload

      assert_equal orga, contact.owner
      assert_not_equal location2, contact.location
      assert_not_equal location2.id, contact.location.id
      assert_equal 'Neues Büro', contact.location.title
      assert_equal orga, contact.location.owner
      assert_equal contact, contact.location.contact
    end

    private

    def save_contact(orga, hash)
      orga.save_contact(ActionController::Parameters.new(hash))
    end

    should 'update (contact with own location) with no location and delete own location' do
      orga = create(:orga)
      location = create(:afeefa_office, owner: orga)
      contact = create(:contact, owner: orga, location: location)
      location.update(contact: contact)

      assert_equal orga, contact.owner
      assert_equal location, contact.location
      assert_equal 'Bayrische Str.8', location.street
      assert_equal orga, location.owner
      assert_equal contact, location.contact

      assert_difference -> { DataPlugins::Location::Location.count }, -1 do
        save_contact(orga, {action: 'update', id: contact.id, location_id: nil})
      end

      contact.reload

      assert_equal orga, contact.owner
      assert_nil contact.location
    end

    should 'remove (contact with own location) and delete own location' do
      orga = create(:orga)
      location = create(:afeefa_office, owner: orga)
      contact = create(:contact, owner: orga, location: location)
      location.update(contact: contact)

      assert_difference -> { DataPlugins::Contact::Contact.count }, -1 do
        assert_difference -> { DataPlugins::Location::Location.count }, -1 do
          orga.delete_contact({id: contact.id})
        end
      end
    end

    should 'remove (contact with linked location) and not delete linked location' do
      orga2 = create(:another_orga)
      contact2 = create(:contact)
      location2 = create(:afeefa_office, contact: contact2, owner: orga2)
      contact2.update(location: location2)

      orga = create(:orga)
      contact = create(:contact, owner: orga, location: location2)

      assert_difference -> { DataPlugins::Contact::Contact.count }, -1 do
        assert_no_difference -> { DataPlugins::Location::Location.count }, 0 do
          orga.delete_contact({id: contact.id})
        end
      end

      contact2.reload

      location = contact2.location
      assert_equal contact2, location.contact
      assert_equal orga2, location.owner
    end

  end
end
