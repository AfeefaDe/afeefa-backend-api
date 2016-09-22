require 'test_helper'

class Orga::Operations::CreateSubOrgaTest < ActiveSupport::TestCase

  context 'As admin' do
    setup do
      @admin = admin
      @user = User.new

      @orga = @admin.orgas.first
    end

    should 'I want to create a new suborga for my orga' do
      assert_difference('@orga.sub_orgas.count') do
        response, operation = Orga::Operations::CreateSubOrga.run(
            {
                current_user: @admin,
                data: {
                    attributes: {
                        parent_id: @orga.id,
                        title: 'super-awesome orga',
                        description: 'this orga is magnificent'
                    },
                    type: 'orga'
                }
            }
        )
        assert(response)
        assert_instance_of(Orga, operation.model)
        assert_equal Orga.find_by_title('super-awesome orga'), @orga.reload.children.last
        assert @admin.orga_admin?(Orga.find_by_title('super-awesome orga'))
      end
    end

    should 'I must not create a invalid suborga' do
      # existing title
      assert_no_difference('@orga.sub_orgas.count') do
        response, operation = Orga::Operations::CreateSubOrga.run(
            {
                current_user: @admin,
                data: {
                    attributes: {
                        parent_id: @orga.id,
                        title: @orga.title,
                        description: 'this orga is magnificent'
                    },
                    type: 'orga'
                }
            }
        )
        assert_not(response)
      end

      # too short title
      assert_no_difference('@orga.sub_orgas.count') do
        response, operation = Orga::Operations::CreateSubOrga.run(
            {
                current_user: @admin,
                data: {
                    attributes: {
                        parent_id: @orga.id,
                        title: '123',
                        description: 'this orga is magnificent'
                    },
                    type: 'orga'
                }
            }
        )
        assert_not(response)
      end

      #no parent orga id
      assert_no_difference('@orga.sub_orgas.count') do
        response, operation = Orga::Operations::CreateSubOrga.run(
            {
                current_user: @admin,
                data: {
                    attributes: {
                        title: 'this is a proper title',
                        description: 'this orga is magnificent'
                    },
                    type: 'orga'
                }
            }
        )
        assert_not(response)
      end
    end
  end
end
