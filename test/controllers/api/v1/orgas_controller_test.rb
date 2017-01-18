require 'test_helper'

class Api::V1::OrgasControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get index' do
      # useful sample data
      orga = create(:orga)
      orga.annotations.create(title: 'annotation123')
      orga.annotations.last

      get :index, params: { include: 'annotations,category,sub_category' }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal Orga.count, json['data'].size
      assert json['included'].any?
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

      should 'I want to create a new orga' do
        params = parse_json_file do |payload|
          payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
          payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
          payload.gsub!('<annotation_id_1>', Annotation.first.id.to_s)
          payload.gsub!('<annotation_id_2>', Annotation.second.id.to_s)
        end
        params['data']['attributes'].merge!('active' => true)

        assert_difference 'Orga.count' do
          assert_no_difference 'Annotation.count' do
            assert_difference 'AnnotationAbleRelation.count', 2 do
              post :create, params: params
              assert_response :created, response.body
            end
          end
        end
        json = JSON.parse(response.body)
        assert_equal StateMachine::ACTIVE.to_s, Orga.last.state
        assert_equal true, json['data']['attributes']['active']

        # Then we could deliver the mapping there
        %w(annotations locations contact_infos).each do |relation|
          assert json['data']['relationships'][relation]['data'].any?, "No element for relation #{relation} found."
          assert_equal relation, json['data']['relationships'][relation]['data'].first['type']
          assert_equal(
            Orga.last.send(relation).first.id.to_s,
            json['data']['relationships'][relation]['data'].first['id'])
          unless relation == 'annotations'
            internal_id = json['data']['relationships'][relation]['data'].first['attributes']['__id__']
            assert(internal_id,
              "Attribute __id__ not found for #{relation}. \n" +
                "Found the following data: #{json['data']['relationships'][relation]['data']}")
            assert_match(/\d+internal-model/, internal_id, "invalid pattern for __id__: #{internal_id}")
          end
        end
      end

      should 'fail for invalid' do
        assert_no_difference 'Orga.count' do
          assert_no_difference 'Annotation.count' do
            assert_no_difference 'ContactInfo.count' do
              assert_no_difference 'Location.count' do
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
            end
          end
        end
      end

      should 'update orga with nested attributes' do
        orga = create(:orga, title: 'foobar')
        orga.annotations.create(title: 'annotation123')
        annotation = orga.annotations.last

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
                      payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
                      payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
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
      end

      should 'soft destroy orga' do
        assert_not @orga.reload.deleted?

        assert_no_difference 'Orga.count' do
          assert_difference 'Orga.undeleted.count', -1 do
            assert_no_difference 'ContactInfo.count' do
              assert_no_difference 'Location.count' do
                assert_no_difference 'Annotation.count' do
                  delete :destroy,
                    params: {
                      id: @orga.id,
                    }
                  assert_response :no_content, response.body
                end
              end
            end
          end
        end
        assert @orga.reload.deleted?
      end

      should 'not soft destroy orga with associated sub_orga' do
        assert sub_orga = create(:another_orga, parent_id: @orga.id)
        assert_equal @orga.id, sub_orga.parent_id
        assert @orga.reload.sub_orgas.any?
        assert_not @orga.reload.deleted?

        assert_no_difference 'Orga.count' do
          assert_no_difference 'Orga.undeleted.count' do
            assert_no_difference 'ContactInfo.count' do
              assert_no_difference 'Location.count' do
                assert_no_difference 'Annotation.count' do
                  delete :destroy,
                    params: {
                      id: @orga.id,
                    }
                  assert_response :locked, response.body
                  json = JSON.parse(response.body)
                  assert_equal 'Unterorganisationen müssen gelöscht werden', json['errors'].first['detail']
                end
              end
            end
          end
        end
        assert_not @orga.reload.deleted?
      end

      should 'not soft destroy orga with associated event' do
        assert event = create(:event, orga_id: @orga.id)
        assert_equal @orga.id, event.orga_id
        assert @orga.reload.events.any?
        assert_not @orga.reload.deleted?

        assert_no_difference 'Orga.count' do
          assert_no_difference 'Orga.undeleted.count' do
            assert_no_difference 'Event.count' do
              assert_no_difference 'Event.undeleted.count' do
                assert_no_difference 'ContactInfo.count' do
                  assert_no_difference 'Location.count' do
                    assert_no_difference 'Annotation.count' do
                      delete :destroy,
                        params: {
                          id: @orga.id,
                        }
                      assert_response :locked, response.body
                      json = JSON.parse(response.body)
                      assert_equal 'Ereignisse müssen gelöscht werden', json['errors'].first['detail']
                    end
                  end
                end
              end
            end
          end
        end
        assert_not @orga.reload.deleted?
      end
    end
  end

end
