require 'test_helper'

class Api::V1::LocationsControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    context 'with given orga' do
      setup do
        @orga = create(:orga)
      end

      should 'I want to create a location' do
        post :create, params: {
          data: {
            type: 'locations',
            attributes: {
              lat: '51.123456',
              lon: '17.123456',
              street: 'Diese komische Straße',
              number: '11abc',
              placename: 'äh, dort um die ecke',
              zip: '01309',
              city: 'Dresden'
            },
            relationships: {
              locatable: {
                data: {
                  id: @orga.id,
                  type: 'orgas'
                }
              }
            }
          }
        }
        assert_response :created, response.body
      end

      should 'destroy a location' do
        assert location = create(:location, locatable: Orga.root_orga)
        delete :destroy, params: { id: location.id }
        assert_response :no_content, response.body
      end
    end
  end

end
