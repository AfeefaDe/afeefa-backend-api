require 'test_helper'

module DataModules::Actor
  class HasActorRelationsTest < ActiveSupport::TestCase

    test 'remove actor relations on remove actor' do
      actor = create(:orga)
      partner = create(:orga_with_random_title)
      partner2 = create(:orga_with_random_title)
      project = create(:orga_with_random_title)
      project_initiator = create(:orga_with_random_title)
      network = create(:orga_with_random_title)
      network_member = create(:orga_with_random_title)

      actor.partners_i_have_associated << partner
      actor.partners_that_associated_me << partner2
      actor.projects << project
      actor.project_initiators << project_initiator
      actor.networks << network
      actor.network_members << network_member

      assert_difference 'Orga.count', -1 do
        assert_difference 'DataModules::Actor::ActorRelation.count', -6 do
          actor.destroy!
        end
      end
    end

    test 'remove actor relations on remove related actor' do
      actor = create(:orga)
      partner = create(:orga_with_random_title)
      partner2 = create(:orga_with_random_title)

      actor.partners_i_have_associated << partner
      actor.partners_i_have_associated << partner2

      assert_difference 'Orga.count', -1 do
        assert_difference 'DataModules::Actor::ActorRelation.count', -1 do
          partner2.destroy!

          assert_equal 1, actor.partners.count
          assert_equal partner, actor.partners.first
        end
      end
    end

    test 'do not remove projects on initiator removal' do
      actor = create(:orga)
      partner = create(:orga_with_random_title)
      partner2 = create(:orga_with_random_title)

      actor.projects << partner
      actor.projects << partner2

      assert_difference 'Orga.count', -1 do
        assert_difference 'DataModules::Actor::ActorRelation.count', -2 do
          actor.destroy!
        end
      end
    end

    test 'deliver partner is associated from right or from left' do
      actor = create(:orga)
      partner = create(:orga_with_random_title)
      partner2 = create(:orga_with_random_title)

      actor.partners_i_have_associated << partner
      partner2.partners_i_have_associated << actor

      assert_equal 2, actor.partners.count
      assert_equal partner, actor.partners.first
      assert_equal partner2, actor.partners.second
    end

  end
end
