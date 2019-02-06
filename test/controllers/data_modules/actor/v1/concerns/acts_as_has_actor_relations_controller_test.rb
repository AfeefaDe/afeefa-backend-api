module ActsAsHasActorRelationsControllerTest
  extend ActiveSupport::Concern

  included do

    setup do
      stub_current_user
      @actor = create(:orga)
      @actor2 = create(:orga_with_random_title)
      @actor3 = create(:orga_with_random_title)
      @actor4 = create(:orga_with_random_title, area: 'hosenmatz')
    end

    def self.test_attach_one(scope, relationName, reverseRelationName, actionName)
      test "link single actor: #{relationName}" do
        assert_no_difference -> { Orga.count } do
          assert_difference -> { DataModules::Actor::ActorRelation.public_send(scope).count }, 1 do
            post actionName, params: { id: @actor.id, actor: @actor2.id }
            assert_response :created, response.body
            assert response.body.blank?
          end
        end

        assert_equal @actor, @actor2.send(reverseRelationName).first
        assert_equal [@actor2], @actor.send(relationName)
      end

      test "throw error if related actor is invalid:  #{relationName}" do
        assert_no_difference -> { Orga.count } do
          assert_no_difference -> { DataModules::Actor::ActorRelation.public_send(scope).count } do
            post actionName, params: { id: @actor.id, actor: @actor4.id } # area
            assert_response :unprocessable_entity
            assert response.body.blank?

            post actionName, params: { id: @actor.id, actor: Orga.last.id + 1 }
            assert_response :unprocessable_entity
            assert response.body.blank?

            post actionName, params: { id: @actor.id }
            assert_response :unprocessable_entity
            assert response.body.blank?

            post actionName, params: { id: @actor.id, actor: [] }
            assert_response :unprocessable_entity
            assert response.body.blank?
          end
        end
      end
    end

    def self.test_detach_one(scope, relationName, reverseRelationName, actionName)
      test "unlink single actor: #{relationName}" do
        @actor.project_initiators << @actor2
        assert_equal @actor, @actor2.send(reverseRelationName).first
        assert_equal [@actor2], @actor.send(relationName)

        assert_no_difference -> { Orga.count } do
          assert_difference -> { DataModules::Actor::ActorRelation.public_send(scope).count }, -1 do
            delete actionName, params: { id: @actor.id, actor: @actor2.id }
            assert_response :ok, response.body
            assert response.body.blank?
          end
        end

        @actor.reload
        @actor2.reload

        assert_nil @actor2.send(reverseRelationName).first
        assert_equal [], @actor.send(relationName)
      end

      test "throw error on wrong parameters: #{relationName}" do
        @actor.project_initiators << @actor2
        assert_equal @actor, @actor2.send(reverseRelationName).first
        assert_equal [@actor2], @actor.send(relationName)

        assert_no_difference -> { Orga.count } do
          assert_no_difference -> { DataModules::Actor::ActorRelation.public_send(scope).count } do
            delete actionName, params: { id: @actor.id, actor: Orga.last.id }
            assert_response :unprocessable_entity
            assert response.body.blank?

            delete actionName, params: { id: @actor.id }
            assert_response :unprocessable_entity
            assert response.body.blank?

            delete actionName, params: { id: @actor.id, actor: [] }
            assert_response :unprocessable_entity
            assert response.body
          end
        end
      end
    end

    def self.test_association(scope, relationName, reverseRelationName, actionName)
      test "link actors: #{relationName}" do
        assert_no_difference -> { Orga.count } do
          assert_difference -> { DataModules::Actor::ActorRelation.public_send(scope).count }, 2 do
            post actionName, params: { id: @actor.id, actors: [@actor2.id, @actor3.id] }
            assert_response :created, response.body
            assert response.body.blank?
          end
        end

        assert_equal @actor, @actor2.send(reverseRelationName).first
        assert_equal @actor, @actor3.send(reverseRelationName).first
        assert_equal [@actor2, @actor3], @actor.send(relationName)

        assert_no_difference -> { Orga.count } do
          assert_difference -> { DataModules::Actor::ActorRelation.public_send(scope).count }, -1 do
            post actionName, params: { id: @actor.id, actors: [@actor2.id] }
            assert_response :created, response.body
            assert response.body.blank?
          end
        end

        @actor.reload
        assert_equal @actor, @actor2.send(reverseRelationName).first
        assert_nil @actor3.send(reverseRelationName).first
        assert_equal [@actor2], @actor.send(relationName)

        assert_no_difference -> { Orga.count } do
          assert_difference -> { DataModules::Actor::ActorRelation.public_send(scope).count }, -1 do
            request.headers['Content-Type'] = 'application/json' # https://github.com/rails/rails/issues/26569
            post actionName, params: { id: @actor.id, actors: [] }
            assert_response :created, response.body
            assert response.body.blank?
          end
        end

        @actor.reload
        assert_nil @actor2.send(reverseRelationName).first
        assert_nil @actor3.send(reverseRelationName).first
        assert_equal [], @actor.send(relationName)
      end

      test "throw error if relating actor is invalid:  #{relationName}" do
        assert_no_difference -> { Orga.count } do
          assert_no_difference -> { DataModules::Actor::ActorRelation.public_send(scope).count } do
            post actionName, params: { id: -456, actors: [@actor2.id, @actor3.id] }
            assert_response :not_found, response.body
            assert response.body.blank?
          end
        end
      end

      test "throw error if one related actor is invalid:  #{relationName}" do
        assert_no_difference -> { Orga.count } do
          assert_no_difference -> { DataModules::Actor::ActorRelation.public_send(scope).count } do
            post actionName, params: { id: @actor.id, actors: [@actor2.id, Orga.last.id + 1] }
            assert_response :unprocessable_entity
            assert response.body.blank?
          end
        end
      end

      test "throw error if one related actor belongs to wrong area:  #{relationName}" do
        assert_no_difference -> { Orga.count } do
          assert_no_difference -> { DataModules::Actor::ActorRelation.public_send(scope).count } do
            post actionName, params: { id: @actor.id, actors: [@actor2.id, @actor4.id] }
            assert_response :unprocessable_entity
            assert response.body.blank?
          end
        end
      end
    end

    test_association('project', :projects, :project_initiators, :link_projects)

    test_association('project', :project_initiators, :projects, :link_project_initiators)

    test_association('network', :network_members, :networks, :link_network_members)

    test_association('network', :networks, :network_members, :link_networks)

    test_association('partner', :partners, :partners, :link_partners)

    test_attach_one('project', :project_initiators, :projects, :link_project_initiators)

    test_detach_one('project', :project_initiators, :projects, :unlink_project_initiator)
  end

end
