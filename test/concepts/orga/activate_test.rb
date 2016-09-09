require 'test_helper'

class Orga::ActivateTest < ActiveSupport::TestCase

  context 'As admin' do
    setup do
      @admin = admin
      @user = User.new

      @orga = @admin.orgas.first
    end

    should 'I want to activate my orga' do
      res, op = Orga::Activate.run(
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
      res, op = Orga::Activate.run(
          {
              id: @orga.id,
              data: {
                  type: 'orga',
                  attributes: {
                      active: false
                  }
              }
          }.merge(user: @admin)
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
  #     @user = user
  #     @orga = orga
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