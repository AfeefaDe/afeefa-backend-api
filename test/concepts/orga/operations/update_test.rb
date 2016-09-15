require 'test_helper'

class Orga::Operations::UpdateTest < ActiveSupport::TestCase

  context 'As admin' do
    setup do
      @admin = admin
      @user = User.new

      @orga = @admin.orgas.first
    end

    should 'I want to update a new suborga for my orga' do
      new_orga_title = 'special new title'
      new_orga_description = 'new description'

      assert_not_equal new_orga_title, @orga.title
      assert_no_difference('Orga.count') do
        response, operation = Orga::Operations::Update.run(
            {
                id: @orga.id,
                current_user: @admin,
                data: {
                    attributes: {
                        title: new_orga_title,
                        description: new_orga_description
                    },
                    type: 'Orga'
                }
            }
        )
        assert(response)
        assert_instance_of(Orga, operation.model)
        assert_equal @orga.reload, operation.model
        assert_equal new_orga_title, @orga.title
        assert_equal new_orga_description, @orga.description
      end
    end

    should 'I must not update a invalid suborga' do
      assert orga2 = Orga.second

      response, operation = Orga::Operations::Update.run(
          {
              id: @orga.id,
              current_user: @admin,
              data: {
                  attributes: {
                      title: orga2.title,
                      description: 'this orga is magnificent'
                  },
                  type: 'Orga'
              }
          }
      )
      assert_not(response)
      assert_equal ['has already been taken'], operation.errors[:title]

      response, operation = Orga::Operations::Update.run(
          {
              id: @orga.id,
              current_user: @admin,
              data: {
                  attributes: {
                      title: '123',
                      description: 'this orga is magnificent'
                  },
                  type: 'Orga'
              }
          }
      )
      assert_not(response)
      assert_equal ['is too short (minimum is 5 characters)'], operation.errors[:title]
    end
  end

end
