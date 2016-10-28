require 'test_helper'

class Api::V1::OrgasControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user(user: User.first)
    end

    should 'get index' do
      orga0 = Orga.new(title: 'Oberoberorga', description: 'Nothing goes above')
      orga0.save(validate: false)
      orga1 = Orga.create(title: 'Afeefa', description: 'Eine Beschreibung für Afeefa', parent_orga: orga0)
      orga2 = Orga.create(title: 'Dresden für Alle e.V.', description: 'Eine Beschreibung für Dresden für Alle e.V.', parent_orga: orga1)
      orga3 = Orga.create(title: 'TU Dresden', description: 'Eine Beschreibung für TU Dresden', parent_orga: orga1)
      orga4 = Orga.create(title: 'Ausländerrat', state: 'edit_request', parent_orga: orga1)
      orga5 = Orga.create(title: 'Frauentreff "Hand in Hand"', state: 'edit_request', parent_orga: orga1)
      orga6 = Orga.create(title: 'Integrations- und Ausländerbeauftragte', parent_orga: orga1)
      orga7 = Orga.create(title: 'Übersetzer Deutsch-Englisch-Französisch', state: 'edit_request', parent_orga: orga1)
      suborga1 = Orga.create(title: 'Interkultureller Frauentreff', parent_orga: orga4, state: 'new')
      suborga2 = Orga.create(title: 'Außenstelle Adlergasse', parent_orga: orga4, state: 'new')

      get :index
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 10, json['data'].size
    end

    should 'get show' do
      orga0 = Orga.new(title: 'Oberoberorga', description: 'Nothing goes above')
      orga0.save(validate: false)

      get :show, params: { id: orga0.id }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Hash, json['data']
    end

  end

end
