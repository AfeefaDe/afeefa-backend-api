require 'test_helper'

class Api::V1::ContactsControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'create contact with location_id and contact_persons' do
      orga = create(:orga)
      location = create(:afeefa_office)

      assert_difference -> { DataPlugins::Contact::Contact.count } do
        assert_difference -> { DataPlugins::Contact::ContactPerson.count }, 2 do
          assert_no_difference -> { DataPlugins::Location::Location.count } do
            post :create,
              params:
                { id: orga.id, owner_type: 'orgas' }.merge(
                  parse_json_file(file: 'create_contract_with_location_id.json') do |payload|
                    payload.gsub!('<location_id>', location.id.to_s)
                  end
                )
            assert_response :created
          end
        end
      end
      json = JSON.parse(response.body)
      contact = DataPlugins::Contact::Contact.last
      assert_equal JSON.parse(contact.to_json), json
      assert_equal location, contact.location
      contact_persons = DataPlugins::Contact::ContactPerson.order(id: :desc)[0..1]
      assert_equal contact_persons.sort, contact.contact_persons.sort
    end

    should 'create contact with new location and contact_persons' do
      orga = create(:orga)

      assert_difference -> { DataPlugins::Contact::Contact.count } do
        assert_difference -> { DataPlugins::Contact::ContactPerson.count }, 2 do
          assert_difference -> { DataPlugins::Location::Location.count } do
            post :create,
              params: { id: orga.id, owner_type: 'orgas' }.merge(parse_json_file(file: 'create_contract_with_new_location.json'))
            assert_response :created
          end
        end
      end
      json = JSON.parse(response.body)
      contact = DataPlugins::Contact::Contact.last
      assert_equal JSON.parse(contact.to_json), json
      location = DataPlugins::Location::Location.last
      assert_equal location, contact.location
      contact_persons = DataPlugins::Contact::ContactPerson.order(id: :desc)[0..1]
      assert_equal contact_persons.sort, contact.contact_persons.sort
    end

    should 'update contact with location_id and without contact_persons' do
      orga = create(:orga)
      location = create(:afeefa_office)
      assert contact = DataPlugins::Contact::Contact.create(owner: orga, location: location, title: 'old title')

      assert_no_difference -> { DataPlugins::Contact::Contact.count } do
        assert_difference -> { DataPlugins::Contact::ContactPerson.count }, 2 do
          assert_no_difference -> { DataPlugins::Location::Location.count } do
            patch :update,
              params:
                { id: orga.id, owner_type: 'orgas', contact_id: contact.id }.merge(
                  parse_json_file(file: 'create_contract_with_location_id.json') do |payload|
                    payload.gsub!('<location_id>', location.id.to_s)
                  end
                )
            assert_response :ok
          end
        end
      end
      json = JSON.parse(response.body)
      contact.reload
      assert_equal JSON.parse(contact.to_json), json
      assert_equal location, contact.location
      contact_persons = DataPlugins::Contact::ContactPerson.order(id: :desc)[0..1]
      assert_equal contact_persons.sort, contact.contact_persons.sort
    end

    should 'update contact with new location and contact_persons' do
      orga = create(:orga)
      assert contact = DataPlugins::Contact::Contact.create(owner: orga, location: nil, title: 'old title')
      assert cp1 = DataPlugins::Contact::ContactPerson.create(role: 'Rolle 1', contact: contact)
      assert cp2 = DataPlugins::Contact::ContactPerson.create(role: 'Rolle 2', contact: contact)

      assert_no_difference -> { DataPlugins::Contact::Contact.count } do
        assert_no_difference -> { DataPlugins::Contact::ContactPerson.count } do
          assert_difference -> { DataPlugins::Location::Location.count } do
            patch :update,
              params:
                { id: orga.id, owner_type: 'orgas', contact_id: contact.id }.merge(
                  parse_json_file(file: 'create_contract_with_new_location.json'))
            assert_response :ok
          end
        end
      end
      json = JSON.parse(response.body)
      contact.reload
      assert_equal JSON.parse(contact.to_json), json
      location = DataPlugins::Location::Location.last
      assert_equal location, contact.location
      contact_persons = DataPlugins::Contact::ContactPerson.order(id: :desc)[0..1]
      assert_equal contact_persons.sort, contact.contact_persons.sort
    end
  end

end
