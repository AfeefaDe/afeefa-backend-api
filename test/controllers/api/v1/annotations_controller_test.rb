require 'test_helper'

class Api::V1::AnnotationsControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    [:orga, :event, :offer].each do |entry_factory|
      should "get annotations for #{entry_factory}" do
        entry = create(entry_factory)

        a1 = Annotation.create!(detail: 'annotation123', entry: entry, annotation_category: AnnotationCategory.first)
        a2 = Annotation.create!(detail: 'annotation456', entry: entry, annotation_category: AnnotationCategory.first)

        get :index, params: { owner_id: entry.id, owner_type: entry_factory.to_s + 's' }
        assert_response :ok

        json = JSON.parse(response.body)
        assert_equal [
          a1.to_hash.deep_stringify_keys,
          a2.to_hash.deep_stringify_keys
        ], json
      end

      should "create annotation for #{entry_factory}" do
        entry = create(entry_factory)

        post :create, params: {
          owner_id: entry.id, owner_type: entry_factory.to_s + 's',
          annotation_category_id: AnnotationCategory.first,
          detail: 'TEST Task'
        }

        assert_response :created
        json = JSON.parse(response.body)
        assert_equal Annotation.last.to_hash.deep_stringify_keys, json
      end

      should "raise error if create annotation fails for #{entry_factory}" do
        entry = create(entry_factory)

        assert_no_difference -> { Annotation.count } do
          post :create, params: {
            owner_id: entry.id, owner_type: 'nix',
            annotation_category_id: AnnotationCategory.first,
            detail: 'TEST Task'
          }
          assert_response :not_found
          assert response.body.blank?

          post :create, params: {
            owner_id: 13456644, owner_type: entry_factory.to_s + 's',
            annotation_category_id: AnnotationCategory.first,
            detail: 'TEST Task'
          }
          assert_response :not_found
          assert response.body.blank?

          post :create, params: {
            owner_id: entry.id, owner_type: entry_factory.to_s + 's',
            detail: 'TEST Task'
          }
          assert_response :unprocessable_entity
          assert_match 'Kategorie fehlt.', response.body

          post :create, params: {
            owner_id: entry.id, owner_type: entry_factory.to_s + 's',
            annotation_category_id: 55555555,
            detail: 'TEST Task'
          }
          assert_response :unprocessable_entity
          assert_match 'Kategorie existiert nicht.', response.body
        end
      end

      should "update annotation for #{entry_factory}" do
        entry = create(entry_factory)

        annotation = Annotation.create!(detail: 'annotation123', entry: entry, annotation_category: AnnotationCategory.first)

        put :update, params: {
          id: annotation.id,
          owner_id: entry.id, owner_type: entry_factory.to_s + 's',
          detail: 'Neuer Name'
        }

        annotation.reload

        assert_response :ok
        json = JSON.parse(response.body)
        assert_equal 'Neuer Name', json['attributes']['detail']
        assert_equal annotation.to_hash.deep_stringify_keys, json

        put :update, params: {
          id: annotation.id,
          owner_id: entry.id, owner_type: entry_factory.to_s + 's'
        }

        annotation.reload

        assert_response :ok
      end

      should "raise error if update annotation fails for #{entry_factory}" do
        entry = create(entry_factory)

        annotation = Annotation.create!(detail: 'annotation123', entry: entry, annotation_category: AnnotationCategory.first)

        put :update, params: {
          id: annotation.id,
          owner_id: 12345, owner_type: entry_factory.to_s + 's',
          detail: 'Neuer Name'
        }
        assert_response :not_found
        assert response.body.blank?

        put :update, params: {
          id: 789654,
          owner_id: entry.id, owner_type: entry_factory.to_s + 's',
          detail: 'Neuer Name'
        }
        assert_response :not_found
        assert response.body.blank?

        put :update, params: {
          id: annotation.id,
          owner_id: entry.id, owner_type: entry_factory.to_s + 's',
          annotation_category_id: 55555555
        }
        assert_response :unprocessable_entity
        assert_match 'Kategorie existiert nicht.', response.body
      end

      should "delete annotation for #{entry_factory}" do
        entry = create(entry_factory)

        annotation = Annotation.create!(detail: 'annotation123', entry: entry, annotation_category: AnnotationCategory.first)

        assert_difference -> { Annotation.count }, -1 do
          put :delete, params: {
            id: annotation.id,
            owner_id: entry.id, owner_type: entry_factory.to_s + 's'
          }
          assert_response :ok
          assert response.body.blank?
        end
      end


      should "raise error if delete annotation fails for #{entry_factory}" do
        entry = create(entry_factory)

        annotation = Annotation.create!(detail: 'annotation123', entry: entry, annotation_category: AnnotationCategory.first)

        assert_no_difference -> { Annotation.count } do
          delete :delete, params: {
            id: 1234,
            owner_id: entry.id, owner_type: entry_factory.to_s + 's'
          }
          assert_response :not_found
          assert response.body.blank?

          delete :delete, params: {
            id: annotation.id,
            owner_id: 1123456, owner_type: entry_factory.to_s + 's'
          }
          assert_response :not_found
          assert response.body.blank?
        end
      end

    end

  end

end
