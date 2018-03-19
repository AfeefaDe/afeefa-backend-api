require 'test_helper'

class DataPlugins::Contact::V1::ContactsControllerTest < ActionController::TestCase

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
                { owner_id: orga.id, owner_type: 'orgas' }.merge(
                  parse_json_file(file: 'contact_with_location_id.json') do |payload|
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
              params: { owner_id: orga.id, owner_type: 'orgas' }.merge(
                parse_json_file(file: 'contact_with_location.json'))
            assert_response :created
          end
        end
      end
      json = JSON.parse(response.body)
      contact = DataPlugins::Contact::Contact.last
      assert_equal JSON.parse(contact.to_json), json
      assert location = DataPlugins::Location::Location.last
      assert_equal location, contact.location
      contact_persons = DataPlugins::Contact::ContactPerson.order(id: :desc)[0..1]
      assert_equal contact_persons.sort, contact.contact_persons.sort
    end

    should 'update contact with location_id and without contact_persons' do
      orga = create(:orga)
      assert location = create(:afeefa_office)
      assert contact = DataPlugins::Contact::Contact.create(owner: orga, location: location, title: 'old title')

      assert_no_difference -> { DataPlugins::Contact::Contact.count } do
        assert_difference -> { DataPlugins::Contact::ContactPerson.count }, 2 do
          assert_no_difference -> { DataPlugins::Location::Location.count } do
            patch :update,
              params:
                { owner_id: orga.id, owner_type: 'orgas', id: contact.id }.merge(
                  parse_json_file(file: 'contact_with_location_id.json') do |payload|
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
      assert contact = DataPlugins::Contact::Contact.create!(owner: orga, location: nil, title: 'old title')
      assert cp1 = DataPlugins::Contact::ContactPerson.create!(role: 'Rolle 1', contact: contact, mail: '123')
      assert cp2 = DataPlugins::Contact::ContactPerson.create!(role: 'Rolle 2', contact: contact, mail: '123')

      assert_no_difference -> { DataPlugins::Contact::Contact.count } do
        assert_no_difference -> { DataPlugins::Contact::ContactPerson.count } do
          assert_difference -> { DataPlugins::Location::Location.count } do
            patch :update,
              params:
                { owner_id: orga.id, owner_type: 'orgas', id: contact.id }.merge(
                  parse_json_file(file: 'contact_with_location.json'))
            assert_response :ok
          end
        end
      end
      json = JSON.parse(response.body)
      contact.reload
      assert_equal JSON.parse(contact.to_json), json
      assert location = DataPlugins::Location::Location.last
      assert_equal location, contact.location
      contact_persons = DataPlugins::Contact::ContactPerson.order(id: :desc)[0..1]
      assert_equal contact_persons.sort, contact.contact_persons.sort
    end

    should 'update contact with update of existing location' do
      new_title = 'New Location'
      orga = create(:orga)
      assert location = DataPlugins::Location::Location.last
      contact = DataPlugins::Contact::Contact.create!(owner: orga, location: location, title: 'old title')
      location.update!(contact: contact)
      assert_equal contact, location.contact
      assert_not_equal new_title, location.title
      cp1 = DataPlugins::Contact::ContactPerson.create!(role: 'Rolle 1', contact: contact, mail: '123')
      cp2 = DataPlugins::Contact::ContactPerson.create!(role: 'Rolle 2', contact: contact, mail: '123')

      assert_no_difference -> { DataPlugins::Contact::Contact.count } do
        assert_no_difference -> { DataPlugins::Contact::ContactPerson.count } do
          assert_no_difference -> { DataPlugins::Location::Location.count } do
            patch :update,
              params:
                { owner_id: orga.id, owner_type: 'orgas', id: contact.id }.merge(
                  parse_json_file(file: 'contact_with_location.json'))
            assert_response :ok
          end
        end
      end
      json = JSON.parse(response.body)
      contact.reload
      assert_equal JSON.parse(contact.to_json), json
      assert_equal location.reload, contact.location.reload
      assert_equal new_title, location.title
      assert_not_includes contact.contact_persons.sort, cp1
      assert_not_includes contact.contact_persons.sort, cp2
      contact_persons = DataPlugins::Contact::ContactPerson.order(id: :desc)[0..1]
      assert_equal contact_persons.sort, contact.contact_persons.sort
    end

    should 'remove contact and including contact persons but not foreign location' do
      orga = create(:orga)
      assert location = DataPlugins::Location::Location.last
      contact = DataPlugins::Contact::Contact.create!(owner: orga, location: location, title: 'old title')
      DataPlugins::Contact::ContactPerson.create!(role: 'Rolle 1', contact: contact, mail: '123')

      assert_difference -> { DataPlugins::Contact::Contact.count }, -1 do
        assert_difference -> { DataPlugins::Contact::ContactPerson.count }, -1 do
          assert_no_difference -> { DataPlugins::Location::Location.count } do
            delete :delete,
              params:
                { owner_id: orga.id, owner_type: 'orgas', id: contact.id }.merge(
                  parse_json_file(file: 'contact_with_location.json'))
            assert_response 200
          end
        end
      end
      assert response.body.blank?
    end

    should 'remove contact and including contact persons and owning location' do
      orga = create(:orga)
      assert location = DataPlugins::Location::Location.last
      contact = DataPlugins::Contact::Contact.create!(owner: orga, location: location, title: 'old title')
      location.update!(contact: contact)
      DataPlugins::Contact::ContactPerson.create!(role: 'Rolle 1', contact: contact, mail: '123')

      assert_difference -> { DataPlugins::Contact::Contact.count }, -1 do
        assert_difference -> { DataPlugins::Contact::ContactPerson.count }, -1 do
          assert_difference -> { DataPlugins::Location::Location.count }, -1 do
            delete :delete,
              params:
                { owner_id: orga.id, owner_type: 'orgas', id: contact.id }.merge(
                  parse_json_file(file: 'contact_with_location.json'))
            assert_response 200
          end
        end
      end
      assert response.body.blank?
    end
  end

end
