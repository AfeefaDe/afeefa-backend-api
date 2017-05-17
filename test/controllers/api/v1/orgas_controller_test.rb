require 'test_helper'

class Api::V1::OrgasControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get index' do
      # useful sample data
      orga = create(:orga)
      Annotation.create!(detail: 'ganz wichtig', entry: orga, annotation_category: AnnotationCategory.first)
      orga.annotations.last
      orga.sub_orgas.create(attributes_for(:another_orga, parent_orga: orga))

      get :index, params: { include: 'annotations,category,sub_category' }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal Orga.count, json['data'].size
      assert_equal Orga.last.to_hash.deep_stringify_keys, json['data'].last
      assert_equal Orga.last.active, json['data'].last['attributes']['active']
    end

    should 'get title filtered list for orgas' do
      user = create(:user)
      orga0 = create(:orga, title: 'Hackathon', description: 'Mate fuer alle!')
      orga1 = create(:orga, title: 'Montagscafe', description: 'Kaffee und so im Schauspielhaus')
      orga2 = create(:orga, title: 'Joggen im Garten', description: 'Gemeinsames Laufengehen im Grossen Garten')

      get :index, params: { filter: { title: 'Garten' } }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 1, json['data'].size

      get :index, params: { filter: { title: 'foo' } }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 0, json['data'].size
    end

    should 'not get show root_orga' do
      not_existing_id = 999
      assert Orga.where(id: not_existing_id).blank?
      get :show, params: { id: not_existing_id }
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
        assert_equal false, json['data']['attributes']['active']
        assert_equal Orga.attribute_whitelist_for_json.sort, json['data']['attributes'].symbolize_keys.keys.sort
        assert_equal Orga.relation_whitelist_for_json.sort, json['data']['relationships'].symbolize_keys.keys.sort
      end

      should 'I want to create a new orga' do
        params = parse_json_file do |payload|
          payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
          payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
          payload.gsub!('<annotation_category_id_1>', AnnotationCategory.first.id.to_s)
          payload.gsub!('<annotation_category_id_2>', AnnotationCategory.second.id.to_s)
        end
        params['data']['attributes'].merge!('active' => true)

        assert_difference 'Orga.count' do
          assert_no_difference 'AnnotationCategory.count' do
            assert_difference 'Annotation.count', 2 do
              post :create, params: params
              assert_response :created, response.body
            end
          end
        end
        json = JSON.parse(response.body)
        assert_equal StateMachine::ACTIVE.to_s, Orga.last.state
        assert_equal true, json['data']['attributes']['active']

        # ensure parent orga handling, do not render root_orga into relations
        assert_equal Orga.root_orga.id, Orga.last.parent_id
        parent_orga_json = json['data']['relationships']['parent_orga']
        assert(parent_orga_json.blank?, 'Parent Orga should not be present in json relations.')

        # Then we could deliver the mapping there
        %w(annotations locations contact_infos).each do |relation|
          assert json['data']['relationships'][relation]['data'].any?, "No element for relation #{relation} found."
          to_check = json['data']['relationships'][relation]['data'].first
          assert_equal relation, to_check['type']
        end
      end

      should 'fail for invalid' do
        assert_no_difference 'Orga.count' do
          assert_no_difference 'AnnotationCategory.count' do
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
                  # 'Beschreibung - muss ausgefüllt werden',
                  # 'Kategorie - ist kein gültiger Wert'
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
        Annotation.create!(detail: 'ganz wichtig', entry: orga, annotation_category: AnnotationCategory.first)
        annotation = orga.reload.annotations.last

        assert_no_difference 'Orga.count' do
          assert_no_difference 'ContactInfo.count' do
            assert_no_difference 'Location.count' do
              assert_no_difference 'AnnotationCategory.count' do
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
        assert_equal annotation, Orga.last.annotations.first
      end

      should 'destroy orga' do
        assert_difference 'Orga.count', -1 do
          assert_difference 'Orga.undeleted.count', -1 do
            assert_no_difference 'ContactInfo.count' do
              assert_no_difference 'Location.count' do
                assert_no_difference 'AnnotationCategory.count' do
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
      end

      should 'not destroy orga with associated sub_orga' do
        assert sub_orga = create(:another_orga, parent_id: @orga.id)
        assert_equal @orga.id, sub_orga.parent_id
        assert @orga.reload.sub_orgas.any?

        assert_no_difference 'Orga.count' do
          assert_no_difference 'Orga.undeleted.count' do
            assert_no_difference 'ContactInfo.count' do
              assert_no_difference 'Location.count' do
                assert_no_difference 'AnnotationCategory.count' do
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
      end

      should 'not destroy orga with associated event' do
        assert event = create(:event, orga_id: @orga.id)
        assert_equal @orga.id, event.orga_id
        assert @orga.reload.events.any?

        assert_no_difference 'Orga.count' do
          assert_no_difference 'Orga.undeleted.count' do
            assert_no_difference 'Event.count' do
              assert_no_difference 'Event.undeleted.count' do
                assert_no_difference 'ContactInfo.count' do
                  assert_no_difference 'Location.count' do
                    assert_no_difference 'AnnotationCategory.count' do
                      delete :destroy,
                        params: {
                          id: @orga.id,
                        }
                      assert_response :locked, response.body
                      json = JSON.parse(response.body)
                      assert_equal 'Events müssen gelöscht werden', json['errors'].first['detail']
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

end
