require 'test_helper'

class Api::V1::PublicControllerTest < ActionController::TestCase
  context 'as authorized user' do
    setup do
      stub_current_user
    end

    context 'with dresden orgas' do
      setup do
        options = { area: 'dresden', state: 'active' }
        @orga = create(:orga, options)
        @orga.sub_orgas.create(attributes_for(:another_orga, parent_orga: @orga, **options))

        Annotation.create!(
          detail: 'dummy annotation',
          entry: @orga,
          annotation_category_id: AnnotationCategory.last.id,
          creator_id: User.first,
          last_editor_id: User.second
        )
      end

      should 'get index actors' do
        get :index_actors, params: { area: 'dresden' }
        assert_response :ok, response.body
        json = JSON.parse(response.body)
        assert_kind_of Array, json['data']
        orgas = Orga.by_area('dresden').active
        assert_equal orgas.count, json['data'].size
        assert_equal(
          orgas.last.to_hash(
            attributes: Orga.lazy_attributes_for_json,
            relationships: Orga.lazy_relations_for_json,
            public: true
          ).deep_stringify_keys,
          json['data'].last
        )

        assert_not json['data'].last['attributes'].key?('support_wanted_detail')
        assert_not json['data'].last['relationships'].key?('resources')

        attributes = json['data'].last['attributes']
        not_wanted_attributes = ['created_at', 'updated_at', 'active']
        ensure_not_wanted_data(attributes, not_wanted_attributes)
      end

      should 'get show actor' do
        get :show_actor, params: { area: 'dresden', id: @orga.id }
        assert_response :ok, response.body
        json = JSON.parse(response.body)
        assert_kind_of Hash, json['data']
        assert_equal @orga.title, json['data']['attributes']['title']

        attributes = json['data']['attributes']
        not_wanted_attributes = ['created_at', 'updated_at', 'active']
        ensure_not_wanted_data(attributes, not_wanted_attributes)

        relationships = json['data']['relationships']
        not_wanted_relationships = ['creator', 'last_editor', 'annotations']
        ensure_not_wanted_data(relationships, not_wanted_relationships)
      end
    end

    context 'with dresden events' do
      setup do
        options = { area: 'dresden', state: 'active' }
        @event = create(:event, options)
      end

      should 'get index events' do
        get :index_events, params: { area: 'dresden' }
        assert_response :ok, response.body
        json = JSON.parse(response.body)
        assert_kind_of Array, json['data']
        events = Event.by_area('dresden').active
        assert_equal events.count, json['data'].size
        assert_equal(
          events.last.to_hash(
            attributes: Event.lazy_attributes_for_json,
            relationships: Event.lazy_relations_for_json,
            public: true
          ).deep_stringify_keys,
          json['data'].last
        )

        assert_not json['data'].last['attributes'].key?('support_wanted_detail')
        assert_not json['data'].last['relationships'].key?('resources')

        attributes = json['data'].last['attributes']
        not_wanted_attributes = ['created_at', 'updated_at', 'active']
        ensure_not_wanted_data(attributes, not_wanted_attributes)
      end

      should 'get show event' do
        get :show_event, params: { area: 'dresden', id: @event.id }
        assert_response :ok, response.body
        json = JSON.parse(response.body)
        assert_kind_of Hash, json['data']
        assert_equal @event.title, json['data']['attributes']['title']

        attributes = json['data']['attributes']
        not_wanted_attributes = ['created_at', 'updated_at', 'active']
        ensure_not_wanted_data(attributes, not_wanted_attributes)

        relationships = json['data']['relationships']
        not_wanted_relationships = ['creator', 'last_editor', 'annotations']
        ensure_not_wanted_data(relationships, not_wanted_relationships)
      end
    end

    context 'with dresden offers' do
      setup do
        options = { area: 'dresden', active: true }
        @offer = create(:offer, options)
      end

      should 'get index offers' do
        get :index_offers, params: { area: 'dresden' }
        assert_response :ok, response.body
        json = JSON.parse(response.body)
        assert_kind_of Array, json['data']
        offers = DataModules::Offer::Offer.by_area('dresden').where(active: true)
        assert_equal offers.count, json['data'].size
        assert_equal(
          offers.last.to_hash(
            attributes: DataModules::Offer::Offer.lazy_attributes_for_json,
            relationships: DataModules::Offer::Offer.lazy_relations_for_json,
            public: true
          ).deep_stringify_keys,
          json['data'].last
        )

        assert_not json['data'].last['attributes'].key?('support_wanted_detail')
        assert_not json['data'].last['relationships'].key?('resources')

        attributes = json['data'].last['attributes']
        not_wanted_attributes = ['created_at', 'updated_at', 'active']
        ensure_not_wanted_data(attributes, not_wanted_attributes)
      end

      should 'get show offer' do
        get :show_offer, params: { area: 'dresden', id: @offer.id }
        assert_response :ok, response.body
        json = JSON.parse(response.body)
        assert_kind_of Hash, json['data']
        assert_equal @offer.title, json['data']['attributes']['title']

        attributes = json['data']['attributes']
        not_wanted_attributes = ['created_at', 'updated_at', 'active']
        ensure_not_wanted_data(attributes, not_wanted_attributes)

        relationships = json['data']['relationships']
        not_wanted_relationships = ['creator', 'last_editor', 'annotations']
        ensure_not_wanted_data(relationships, not_wanted_relationships)
      end
    end
  end

  private

  def ensure_not_wanted_data(data, blacklist, key: 'attribute')
    blacklist.each do |attribute|
      assert !data.key?(attribute), "#{key} #{attribute} should not be present"
    end
  end
end
