require 'test_helper'

class Orga::CreateSubOrgaTest < ActiveSupport::TestCase

  context 'As admin' do
    setup do
      @admin = admin
      @user = User.new

      @orga = @admin.orgas.first
    end

    should 'I want to create a new suborga for my orga' do
      assert_difference('@orga.sub_orgas.count') do
        res, op = Orga::CreateSubOrga.run(
            {
                id: @orga.id,
                user: @admin,
                data: {
                    attributes: {
                        title: 'super-awesome orga',
                        description: 'this orga is magnificent'
                    },
                    type: 'Orga'
                }
            }
        )
        assert(res)
        assert_instance_of(Orga, op.model)
        assert_equal Orga.find_by_title('super-awesome orga'), @orga.reload.children.last
        assert @admin.orga_admin?(Orga.find_by_title('super-awesome orga'))
      end
    end

    should 'I must not create a invalid suborga' do
      assert_no_difference('@orga.sub_orgas.count') do
        res, op = Orga::CreateSubOrga.run(
            {
                id: @orga.id,
                user: @admin,
                data: {
                    attributes: {
                        title: @orga.title,
                        description: 'this orga is magnificent'
                    },
                    type: 'Orga'
                }
            }
        )

        assert_not(res)
      end

      assert_no_difference('@orga.sub_orgas.count') do

        res, op = Orga::CreateSubOrga.run(
            {
                id: @orga.id,
                user: @admin,
                data: {
                    attributes: {
                        title: '123',
                        description: 'this orga is magnificent'
                    },
                    type: 'Orga'
                }
            }
        )

        assert_not(res)
      end
    end
  end

end
