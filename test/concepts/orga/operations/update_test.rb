require 'test_helper'

class Orga::Operations::UpdateTest < ActiveSupport::TestCase

  context 'As admin' do
    setup do
      @admin = admin
      @user = User.new

      @orga = @admin.orgas.first
    end

    should 'I must not update a invalid suborga' do
      assert orga2 = Orga.last

      # title already taken
      response, operation = Orga::Operations::UpdateData.run(
          {
              id: @orga.id,
              current_user: @admin,
              data: {
                  id: @orga.id,
                  attributes: {
                      title: orga2.title,
                      description: 'this orga is magnificent'
                  },
                  type: 'orga'
              }
          }
      )
      assert_not(response)
      assert_equal ['has already been taken'], operation.errors[:title]

      # title too short
      response, operation = Orga::Operations::UpdateData.run(
          {
              id: @orga.id,
              current_user: @admin,
              data: {
                  id: @orga.id,
                  attributes: {
                      title: '123',
                      description: 'this orga is magnificent'
                  },
                  type: 'orga'
              }
          }
      )
      assert_not(response)
      assert_equal ['is too short (minimum is 5 characters)'], operation.errors[:title]
    end

    should 'I want to update the data of my own orga' do
      new_orga_title = 'special new title'
      new_orga_description = 'new description'

      assert_not_equal new_orga_title, @orga.title
      assert_no_difference('Orga.count') do
        response, operation = Orga::Operations::UpdateData.run(
            {
                id: @orga.id,
                current_user: @admin,
                data: {
                    id: @orga.id,
                    attributes: {
                        title: new_orga_title,
                        description: new_orga_description
                    },
                    type: 'orga'
                }
            }
        )
        assert(response)
        assert_instance_of(Orga, operation.model)
        @orga.reload
        assert_equal @orga, operation.model
        assert_equal new_orga_title, @orga.title
        assert_equal new_orga_description, @orga.description
      end
    end

    should 'I want to update data and structure of my own orga' do
      new_parent = Orga.where.not(id: [@orga.parent.id, @orga.id]).first
      new_orga_title = 'very special new title'
      new_orga_description = 'very new description'

      assert_not_equal new_parent, @orga.parent

      assert_no_difference('Orga.count') do
        response, operation = Orga::Operations::UpdateAll.run(
            {
                id: @orga.id,
                current_user: @admin,
                data: {
                    id: @orga.id,
                    attributes: {
                        title: new_orga_title,
                        description: new_orga_description
                    },
                    type: 'orga',
                    relationships: {
                        parent: {
                            data: {
                                type: 'orga',
                                id: new_parent.id
                            }
                        }
                    }
                }
            }
        )
        assert(response)
        assert_instance_of(Orga, operation.model)
        @orga.reload
        assert_equal @orga, operation.model
        assert_equal new_orga_title, @orga.title
        assert_equal new_orga_description, @orga.description
        assert_equal new_parent, @orga.parent
      end
    end
  end
end
