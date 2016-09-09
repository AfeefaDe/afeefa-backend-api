require 'test_helper'

class Orga::OperationTest < ActiveSupport::TestCase

  context 'As admin' do
    setup do
      @admin = create(:admin)
      @user = create(:user)

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

    should 'I want to activate my orga' do
      res, op = Orga::ActivateOrga.run(
          {
              id: @orga.id,
              data: {
                  type: 'orga',
                  attributes: {
                      active: true
                  }
              }
          }
      )
      assert(res)
      assert_equal true, op.model.active
    end

    should 'I want to deactivate my orga' do
      res, op = Orga::ActivateOrga.run(
          {
              id: @orga.id,
              data: {
                  type: 'orga',
                  attributes: {
                      active: false
                  }
              }
          }
      )
      assert(res)
      assert_equal false, op.model.active
    end
  end

  # context 'As member' do
  #   setup do
  #     @member = create(:member, orga: build(:orga))
  #     @orga = @member.orgas.first
  #     stub_current_user(user: @member)
  #   end
  #
  #   should 'I must not activate my orga' do
  #     active = @orga[:active]
  #     post :activate, id: @orga.id
  #     assert_response :forbidden
  #     @orga.reload
  #     assert_equal @orga[:active], active
  #   end
  #
  #   should 'I must not deactivate my orga' do
  #     active = @orga[:active]
  #     post :deactivate, id: @orga.id
  #     assert_response :forbidden
  #     @orga.reload
  #     assert_equal @orga[:active], active
  #   end
  #
  # end
  #
  # context 'As user' do
  #   setup do
  #     @user = create(:user)
  #     @orga = create(:orga)
  #     stub_current_user(user: @user)
  #   end
  #
  #   should 'I must not activate some orga' do
  #     active = @orga[:active]
  #     post :activate, id: @orga.id
  #     assert_response :forbidden
  #     @orga.reload
  #     assert_equal @orga[:active], active
  #   end
  #
  #   should 'I must not deactivate some orga' do
  #     active = @orga[:active]
  #     post :deactivate, id: @orga.id
  #     assert_response :forbidden
  #     @orga.reload
  #     assert_equal @orga[:active], active
  #   end
  # end


end
