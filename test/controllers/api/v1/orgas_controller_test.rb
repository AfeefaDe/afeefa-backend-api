require 'test_helper'

class Api::V1::OrgasControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get index' do
      get :index
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal Orga.count, json['data'].size
    end

    should 'not get show root_orga' do
      not_existing_id = 999
      assert Orga.where(id: not_existing_id).blank?
      get :show, params: { id: not_existing_id }
      assert_response :not_found, response.body
    end

    should 'not get related_resource for root_orga' do
      event =
        create(:event, title: 'Hackathon',
          description: 'Mate fuer alle!', creator: User.first, orga: Orga.root_orga)
      get :get_related_resource, params: {
        event_id: event.id,
        relationship: 'orga',
        source: 'api/v1/events'
      }
      assert_response :not_found, response.body
    end

    context 'with given orga' do
      setup do
        @orga = create(:orga)
      end

      should 'get show' do
        get :show, params: { id: @orga.id }
        assert_response :ok, response.body
        json = JSON.parse(response.body)
        assert_kind_of Hash, json['data']
      end

      should 'fail for invalid' do
        post :create, params: {
          data: {
            type: 'orgas',
            attributes: {
            },
            relationships: {
            }
          }
        }
        assert_response :unprocessable_entity, response.body
        json = JSON.parse(response.body)
        assert_equal(
          [
            'Titel - muss ausgefüllt werden',
            'Beschreibung - muss ausgefüllt werden',
            'Kategorie - ist kein gültiger Wert'
          ],
          json['errors'].map { |x| x['detail'] }
        )
      end

      should 'I want to create a new orga' do
        Orga.any_instance.stubs(:valid?).returns(true)

        post :create, params: {
          data: {
            type: 'orgas',
            attributes: {
              title: 'some title',
              description: 'some description',
              category: Able::CATEGORIES.first,
              state_transition: 'activate'
            },
            relationships: {
              parent_orga: {
                data: {
                  id: @orga.id,
                  type: 'orgas'
                }
              }
            }
          }
        }
        assert_response :created, response.body
        json = JSON.parse(response.body)
        assert_equal StateMachine::ACTIVE.to_s, json['data']['attributes']['state']
      end

      should 'An orga should only change allowed states' do
        # allowed transition active -> inactive
        active_orga = create(:active_orga)
        assert active_orga.active?
        last_state_change = active_orga.state_changed_at
        last_update = active_orga.state_changed_at

        sleep(1)

        process :update, methode: :patch, params: {
          id: active_orga.id,
          data: {
            id: active_orga.id,
            type: 'orgas',
            attributes: {
              state_transition: 'deactivate'
            }
          }
        }

        assert_response :ok, response.body

        json = JSON.parse(response.body)

        assert last_state_change < json['data']['attributes']['state_changed_at'], "#{last_state_change} is not newer than #{json['data']['attributes']['state_changed_at']}"
        assert last_update < json['data']['attributes']['updated_at']
        assert active_orga.reload.inactive?

      end

      should 'ignore given state on orga create' do
        Orga.any_instance.stubs(:valid?).returns(true)

        post :create, params: {
          data: {
            type: 'orgas',
            attributes: {
              title: 'some title',
              description: 'some description',
              category: Able::CATEGORIES.first,
              state: StateMachine::ACTIVE.to_s
            },
            relationships: {
              parent_orga: {
                data: {
                  id: @orga.id,
                  type: 'orgas'
                }
              }
            }
          }
        }
        assert_response :created, response.body
        assert_equal 'some title', Orga.last.title
        assert Orga.last.inactive?
        json = JSON.parse(response.body)
        assert_equal StateMachine::INACTIVE.to_s, json['data']['attributes']['state']
      end

      should 'set default orga on orga create without parent relation' do
        post :create,
          params: parse_json_file(file: 'create_orga_without_parent.json')
        assert_response :created, response.body
        assert_equal 'some title', Orga.last.title
        assert_equal Orga.root_orga.id, Orga.last.parent_orga_id
      end

      should 'set default orga on orga create with parent relation with id nil' do
        skip 'jsonapi gem does not support this'
        post :create, params: {
          data: {
            type: 'orgas',
            attributes: {
              title: 'some title',
              description: 'some description',
              category: Able::CATEGORIES.first,
            },
            relationships: {
              parent_orga: {
                data: {
                  id: nil,
                  type: 'orgas'
                }
              }
            }
          }
        }
        assert_response :created, response.body
        assert_equal 'some title', Orga.last.title
        assert_equal Orga.root_orga.id, Orga.last.parent_orga_id
      end

      should 'create orga with nested attributes' do
        annotation = Annotation.new(title: '000', annotatable: Orga.last)
        assert annotation.save

        assert_difference 'Orga.count' do
          assert_difference 'Annotation.count', 2 do
            assert_difference 'ContactInfo.count' do
              params = parse_json_file do |payload|
                payload.gsub!('<annotation_id_1>', annotation.id.to_s)
              end
              post :create, params: params
              assert_response :created, response.body
              get :show, params: { id: Orga.last.id }
              assert_response :ok, response.body
            end
          end
        end
        assert_equal 'some title', Orga.last.title
        assert_equal Orga.root_orga.id, Orga.last.parent_orga_id
        assert_equal '377436332', ContactInfo.last.phone
        assert_equal Orga.last, ContactInfo.last.contactable
        assert_equal 2, Orga.last.annotations.count
      end

      should 'update orga with nested attributes' do
        orga = create(:orga, title: 'foobar')
        assert Annotation.create(title: 'annotation123', annotatable: orga)
        annotation = Annotation.last

        assert_no_difference 'Orga.count' do
          assert_no_difference 'ContactInfo.count' do
            assert_no_difference 'Location.count' do
              assert_no_difference 'Annotation.count' do
                post :update,
                  params: {
                    id: orga.id,
                  }.merge(
                    parse_json_file(
                      file: 'update_orga_with_nested_models.json'
                    ) do |payload|
                      payload.gsub!('<id>', orga.id.to_s)
                      payload.gsub!('<annotation_id_1>', annotation.id.to_s)
                      # pp JSON.parse(payload)
                    end
                  )
                assert_response :ok, response.body
              end
            end
          end
        end
        assert_equal 'Ein Test 3', Orga.last.title
        assert_equal Orga.root_orga.id, Orga.last.parent_orga_id
        assert_equal '0123456789', ContactInfo.last.phone
        assert_equal Orga.last, ContactInfo.last.contactable
        assert_equal 1, Orga.last.annotations.count
        assert_equal annotation.reload, Orga.last.annotations.first
        assert_equal 'Hallo Welt 2', annotation.reload.title
      end
    end
  end

end
