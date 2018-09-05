require 'test_helper'

class DataPlugins::Contact::V1::ContactsControllerTest < ActionController::TestCase
  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'not create contact for owner with already existing contact' do
      orga = create(:orga, title: 'creator')
      location = create(:afeefa_office)
      contact =
        DataPlugins::Contact::Contact.create(owner: orga, location: location, title: 'already existing contact')
      assert contact
      assert orga.update(contact_id: contact.id)

      assert_no_difference -> { DataPlugins::Contact::Contact.count } do
        assert_no_difference -> { DataPlugins::Contact::ContactPerson.count } do
          assert_no_difference -> { DataPlugins::Location::Location.count } do
            post :create,
              params:
                { owner_id: orga.id, owner_type: 'orgas' }.merge(
                  parse_json_file(file: 'contact_with_location_id.json') do |payload|
                    payload.gsub!('<location_id>', location.id.to_s)
                  end
                )
            assert_response :unprocessable_entity
          end
        end
      end
      json = JSON.parse(response.body)
      assert_equal 'There is already a linked contact given.', json['error']
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
      assert orga.contacts.blank?
      assert orga.contacts.blank?

      assert_difference -> { DataPlugins::Contact::Contact.count } do
        assert_difference -> { DataPlugins::Contact::ContactPerson.count }, 2 do
          assert_difference -> { DataPlugins::Location::Location.count } do
            post :create,
              params:
                { owner_id: orga.id, owner_type: 'orgas' }.
                  merge(parse_json_file(file: 'contact_with_location.json'))
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

    should 'not update contact not owned by owner' do
      orga_editing = create(:orga, title: 'editor')
      orga_owning = create(:orga, title: 'owner')
      assert location = create(:afeefa_office)
      assert contact = DataPlugins::Contact::Contact.create(owner: orga_owning, location: location, title: 'old title')

      assert_no_difference -> { DataPlugins::Contact::Contact.count } do
        assert_no_difference -> { DataPlugins::Contact::ContactPerson.count } do
          assert_no_difference -> { DataPlugins::Location::Location.count } do
            patch :update,
              params:
                { owner_id: orga_editing.id, owner_type: 'orgas', id: contact.id }.merge(
                  parse_json_file(file: 'contact_with_location_id.json') do |payload|
                    payload.gsub!('<location_id>', location.id.to_s)
                  end
                )
            assert_response :unprocessable_entity
          end
        end
      end
      json = JSON.parse(response.body)
      assert_equal 'The given contact is not linked by you.', json['error']
    end

    should 'not link not existing contact' do
      orga = create(:orga, title: 'editor')

      assert_no_difference -> { DataPlugins::Contact::Contact.count } do
        assert_no_difference -> { DataPlugins::Contact::ContactPerson.count } do
          assert_no_difference -> { DataPlugins::Location::Location.count } do
            patch :update, params: { owner_id: orga.id, owner_type: 'orgas', id: 'not-existing-id' }
            assert_response :not_found
          end
        end
      end
      assert response.body.blank?
    end

    should 'link existing external contact' do
      assert orga_editing = create(:orga, title: 'editor')
      assert orga_owning = create(:orga, title: 'owner')
      assert location = create(:afeefa_office)
      assert contact = DataPlugins::Contact::Contact.create(owner: orga_owning, location: location, title: 'old title')
      assert orga_editing.contacts.blank?

      assert_no_difference -> { DataPlugins::Contact::Contact.count } do
        assert_no_difference -> { DataPlugins::Contact::ContactPerson.count } do
          assert_no_difference -> { DataPlugins::Location::Location.count } do
            post :create, params: { owner_id: orga_editing.id, owner_type: 'orgas', id: contact.id }
            assert_response :created, response.body
          end
        end
      end
      assert_equal contact, orga_editing.reload.linked_contact
      json = JSON.parse(response.body)
      contact.reload
      assert_equal JSON.parse(contact.to_json), json
    end

    should 'not link existing external contact if own contact given' do
      orga_editing = create(:orga, title: 'editor')
      orga_owning = create(:orga, title: 'owner')
      contact_to_link =
        DataPlugins::Contact::Contact.create(
          owner: orga_owning, location: create(:afeefa_office), title: 'contact to link'
        )
      assert contact_to_link
      location_existing = create(:location_dresden)
      contact_existing =
        DataPlugins::Contact::Contact.create(
          owner: orga_editing, location: location_existing, title: 'existing old contact'
        )
      assert contact_existing
      assert location_existing.update(contact: contact_existing)
      assert_equal [contact_existing], orga_editing.contacts
      assert orga_editing.linked_contact.blank?

      assert_no_difference -> { DataPlugins::Contact::Contact.count } do
        assert_no_difference -> { DataPlugins::Location::Location.count } do
          post :create, params: { owner_id: orga_editing.id, owner_type: 'orgas', id: contact_to_link.id }
          assert_response :unprocessable_entity, response.body
        end
      end
      json = JSON.parse(response.body)
      assert_equal 'There is already an owned contact given.', json['error']
    end

    should 'update contact with location_id and without contact_persons' do
      orga = create(:orga)
      assert location = create(:afeefa_office)
      contact = DataPlugins::Contact::Contact.create!(owner: orga, location: location, title: 'old title')
      orga.update!(linked_contact: contact)

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
            assert_response :ok, response.body
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
      assert orga.update(linked_contact: contact)

      assert_no_difference -> { DataPlugins::Contact::Contact.count } do
        assert_no_difference -> { DataPlugins::Contact::ContactPerson.count } do
          assert_difference -> { DataPlugins::Location::Location.count } do
            patch :update,
              params:
                { owner_id: orga.id, owner_type: 'orgas', id: contact.id }.merge(
                  parse_json_file(file: 'contact_with_location.json'))
            assert_response :ok, response.body
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
      orga.update!(linked_contact: contact)
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
              assert_response :ok, response.body
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

    should 'not remove link and do not remove contact not linked and not owned by owner' do
      orga_editing = create(:orga, title: 'editor')
      orga_owning = create(:orga, title: 'owner')
      assert location = create(:afeefa_office)
      contact =
        DataPlugins::Contact::Contact.create!(owner: orga_owning, location: location, title: 'contact to remove')
      contact_linked =
        DataPlugins::Contact::Contact.create!(owner: orga_owning, location: location, title: 'linked contact')
      orga_editing.update!(linked_contact: contact_linked)

      assert_no_difference -> { DataPlugins::Contact::Contact.count } do
        assert_no_difference -> { DataPlugins::Contact::ContactPerson.count } do
          assert_no_difference -> { DataPlugins::Location::Location.count } do
            delete :delete, params: { owner_id: orga_editing.id, owner_type: 'orgas', id: contact.id }
            assert_response :unprocessable_entity, response.body
          end
        end
      end
      json = JSON.parse(response.body)
      assert_equal 'The given contact is not linked by you.', json['error']
      assert_equal contact_linked, orga_editing.linked_contact
    end

    should 'remove link but do not remove contact if not owned by owner' do
      assert orga_editing = create(:orga, title: 'editor')
      assert orga_owning = create(:orga, title: 'owner')
      assert location = create(:afeefa_office)
      contact = DataPlugins::Contact::Contact.create!(owner: orga_owning, location: location, title: 'old title')
      orga_editing.update!(linked_contact: contact)

      assert_no_difference -> { DataPlugins::Contact::Contact.count } do
        assert_no_difference -> { DataPlugins::Contact::ContactPerson.count } do
          assert_no_difference -> { DataPlugins::Location::Location.count } do
            delete :delete, params: { owner_id: orga_editing.id, owner_type: 'orgas', id: contact.id }
            assert_response :ok, response.body
          end
        end
      end
      assert_nil orga_editing.reload.linked_contact
      assert response.body.blank?
    end

    should 'remove contact and including contact persons but not foreign location' do
      orga = create(:orga)
      assert location = DataPlugins::Location::Location.last
      contact = DataPlugins::Contact::Contact.create!(owner: orga, location: location, title: 'old title')
      DataPlugins::Contact::ContactPerson.create!(role: 'Rolle 1', contact: contact, mail: '123')
      orga.update!(linked_contact: contact)

      assert_difference -> { DataPlugins::Contact::Contact.count }, -1 do
        assert_difference -> { DataPlugins::Contact::ContactPerson.count }, -1 do
          assert_no_difference -> { DataPlugins::Location::Location.count } do
            delete :delete,
              params: { owner_id: orga.id, owner_type: 'orgas', id: contact.id }
            assert_response :ok, response.body
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
      orga.update!(linked_contact: contact)

      assert_difference -> { DataPlugins::Contact::Contact.count }, -1 do
        assert_difference -> { DataPlugins::Contact::ContactPerson.count }, -1 do
          assert_difference -> { DataPlugins::Location::Location.count }, -1 do
            delete :delete,
              params: { owner_id: orga.id, owner_type: 'orgas', id: contact.id }
            assert_response :ok, response.body
          end
        end
      end
      assert response.body.blank?
    end

    should 'remove linked location when removing contact with that location' do
      orga = create(:orga)
      assert location = DataPlugins::Location::Location.last
      contact = DataPlugins::Contact::Contact.create!(owner: orga, location: location, title: 'contact1')
      orga.update!(linked_contact: contact)
      assert location.update!(contact: contact)

      contact2 = DataPlugins::Contact::Contact.create!(owner: orga, location: location, title: 'contact2')

      assert_equal contact.location, contact2.location
      assert_equal location.id, contact2.location_id

      assert_difference -> { DataPlugins::Contact::Contact.count }, -1 do
        assert_difference -> { DataPlugins::Location::Location.count }, -1 do
          delete :delete,
            params: { owner_id: orga.id, owner_type: 'orgas', id: contact.id }
          assert_response :ok, response.body
        end
      end
      assert response.body.blank?

      contact2.reload
      assert_nil contact2.location_id
      assert_nil contact2.location
    end
  end
end
