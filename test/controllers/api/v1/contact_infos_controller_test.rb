require 'test_helper'

class Api::V1::ContactInfosControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    context 'with given orga' do
      setup do
        @orga = create(:orga)
      end

      should 'I want to create a new orga' do
        post :create, params: {
          data: {
            type: 'contact_infos',
            attributes: {
              mail: 'test@example.com',
              phone: '0123 -/ 456789',
              contact_person: 'Herr Max Müller'
            }
          }
        }
        assert_response :created, response.body
      end
    end
  end

end
