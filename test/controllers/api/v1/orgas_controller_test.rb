require 'test_helper'

class Api::V1::OrgasControllerTest < ActionController::TestCase

  context 'As Admin' do
    setup do
      @admin = admin
      stub_current_user(user: @admin)

      @orga = @admin.orgas.first
      @user_json = { forename: 'Rudi', surname: 'Dutschke', email: 'bob@afeefa.de' }
    end

    should 'I want to create a suborga for my orga' do
#      Orga::Operations::CreateSubOrga.any_instance.expects(:process).once
      post :create, params: {
          data: {
              type: 'orgas',
              attributes: {
                  title: 'some title',
                  description: 'some description'
              },
              relationships: {
                  parent: {
                      data: {
                          type: 'orgas', id: @orga.id
                      }
                  }
              }
          }
      }
      assert_response :created, response.body
    end

    should 'I want to update the structure of the orga' do
      new_parent_orga = Orga.last
      desc = @orga[:description]
      patch :update, params: {
          id: @orga.id,
          meta: {
              trigger_operation: 'update_structure'
          },
          data: {
              type: 'orgas',
              id: @orga.id,
              attributes: {
                  title: 'newTitle',
              },
              relationships: {
                  parent: {
                      data: {
                          type: 'orgas', id: new_parent_orga.id
                      }
                  }
              }
          }
      }
      assert_response :ok, response.body
      @orga.reload
      assert_equal @orga[:title], 'newTitle'
      assert_equal @orga[:description], desc
    end

    should 'I want to activate my orga' do
      skip 'implement update'
      Orga::Activate.any_instance.expects(:process).once
      patch :update, params: {
          id: @orga.id,
          data: {
              type: 'orgas',
              attributes: {
                  active: true
              }
          }
      }
      assert_response :no_content, response.body
    end

    should 'I want to deactivate my orga' do
      skip 'implement update'
      Orga::Activate.any_instance.expects(:process).once
      patch :update, params: {
          id: @orga.id,
          data: {
              type: 'orgas',
              attributes: {
                  active: false
              }
          }
      }
      assert_response :no_content, response.body
    end

    should 'I must not create a invalid suborga with existing title' do
      post :create, params: {
          data: {
              attributes: {
                  title: @orga.title,
                  description: 'this orga is magnificent'
              },
              relationships: {
                  parent: {
                      data: {
                          type: 'orgas', id: @orga.id
                      }
                  }
              },
              type: 'orgas'
          }
      }
      assert_response :unprocessable_entity, response.body

    end

    should 'I must not create a invalid suborga with too short title' do
      post :create, params: {
          data: {
              attributes: {
                  title: '123',
                  description: 'this orga is very magnificent'
              },
              relationships: {
                  parent: {
                      data: {
                          type: 'orgas', id: @orga.id
                      }
                  }
              },
              type: 'orgas'
          }
      }
      assert_response :unprocessable_entity, response.body

    end

    should 'I must not create a invalid suborga with no parent orga' do
      post :create, params: {
          data: {
              attributes: {
                  title: '12345',
                  description: 'this orga is quite magnificent'
              },
              type: 'orgas'
          }
      }
      assert_response :unprocessable_entity, response.body

    end

    should 'I must not create a invalid suborga with no type' do
      post :create, params: {
          data: {
              attributes: {
                  title: '12345',
                  description: 'this orga is quite magnificent'
              }
          }
      }
      assert_response :bad_request, response.body

    end

    should 'I must not create a invalid suborga with no attributes' do
      post :create, params: {
          data: {
              atributes: {},
              type: 'orgas'
          }
      }
      assert_response :unprocessable_entity, response.body

    end

    should 'I must not create a invalid suborga with no attribute argument' do
      post :create, params: {
          data: {
              type: 'orgas'
          }
      }
      assert_response :bad_request, response.body

    end

    should 'I must not create a invalid suborga with empty data' do
      post :create, params: {
          data: {}
      }
      assert_response :bad_request, response.body

    end

    should 'I must not create a invalid suborga with no data at all' do
      post :create, params: {

      }
      assert_response :bad_request, response.body
    end

    # should 'I want to create a new member in orga' do
    #   assert_difference '@orga.users.count' do
    #     post :create_member, id: @orga.id, user: @user_json
    #     assert_response :created
    #   end
    #
    #   assert_equal @user_json[:email], @orga.users.last.email
    # end

    # should 'I must not create a new member in a not existing orga' do
    #   assert_no_difference 'User.count' do
    #     post :create_member, id: 'not existing id', user: @user_json
    #     assert_response :not_found
    #   end
    # end

    # should 'I must not create a new member in an orga I am no admin in' do
    #   assert_no_difference 'User.count' do
    #     post :create_member, id: create(:another_orga).id, user: @user_json
    #     assert_response :forbidden
    #   end
    # end

    # should 'I must not create a new user that already exists' do
    #   @user = user
    #   assert_no_difference 'User.count' do
    #     post :create_member, id: @orga.id, user: { forename: 'a', surname: 'b', email: @user.email }
    #     assert_response :unprocessable_entity
    #   end
    # end

    # todo: not working…
    should 'I want to delete my orga' do
      assert_difference('Orga.count', -1) do
        assert_difference('Role.count', -1) do
          process :destroy, methode: :delete, params: { id: @orga.id }
        end
      end
      assert_response :no_content
    end

    # context 'interacting with a member' do
    #   setup do
    #     @member = create(:member, orga: @admin.orgas.first)
    #     @user = user
    #   end
    #
    #   should 'I want to try to remove a user from orga' do
    #     @admin.expects(:remove_user_from_orga).once
    #     delete :remove_member, id: @orga.id, user_id: @member.id
    #   end
    #
    #   should 'I want to remove a user from orga' do
    #     delete :remove_member, id: @orga.id, user_id: @member.id
    #     assert_response :no_content
    #   end
    #
    #   should 'I want to remove a user from orga, am not admin, not myself' do
    #     stub_current_user(user: @user)
    #
    #     delete :remove_member, id: @orga.id, user_id: @member.id
    #     assert_response :forbidden
    #   end
    #
    #   should 'I want remove a user from orga, the user not in orga' do
    #     delete :remove_member, id: @orga.id, user_id: @user.id
    #     assert_response :not_found
    #   end
    #
    #   should 'I want to promote a member to admin, user is not in orga' do
    #     put :promote_member, id: @orga.id, user_id: @user.id
    #     assert_response :not_found
    #   end
    #
    #   should 'I want to promote a member to admin, am not admin' do
    #     stub_current_user(user: @user)
    #
    #     put :promote_member, id: @orga.id, user_id: @member.id
    #     assert_response :forbidden
    #   end
    #
    #   should 'I want to promote a member to admin' do
    #     @admin.expects(:promote_member_to_admin).once
    #     put :promote_member, id: @orga.id, user_id: @member.id
    #     assert_response :no_content
    #   end
    #
    #   should 'I want to demote an admin to member, user is not in orga' do
    #     put :demote_admin, id: @orga.id, user_id: @user.id
    #     assert_response :not_found
    #   end
    #
    #   should 'I want to demote an admin to member, am not admin' do
    #     stub_current_user(user: @user)
    #
    #     put :demote_admin, id: @orga.id, user_id: @member.id
    #     assert_response :forbidden
    #   end
    #
    #   should 'I want to demote an admin to member' do
    #     User.any_instance.expects(:demote_admin_to_member).once
    #     put :demote_admin, id: @orga.id, user_id: @member.id
    #     assert_response :no_content
    #   end
    #
    #   should 'I want to add an existing user to my orga' do
    #     Orga.any_instance.expects(:add_new_member).once
    #     put :add_member, id: @orga.id, user_id: @user.id
    #     assert_response :no_content
    #   end
    # end
  end

  context 'As member' do
    setup do
      @member = member
      @orga = @member.orgas.first
      stub_current_user(user: @member)
    end

    # should 'I want a list of all members in the corresponding orga' do
    #   assert_routing 'api/v1/orgas/1/users', controller: 'api/v1/orgas', action: 'list_members', id: '1'
    # end

    # should 'render json api spec for user list' do
    #   get :list_members, id: @orga.id
    #   assert_response :ok
    #   expected = ActiveModelSerializers::SerializableResource.new([@member], {}).to_json
    #   assert_equal expected, response.body
    # end

    # should 'I want to leave orga' do
    #   delete :remove_member, id: @orga.id, user_id: @member.id
    #   assert_response :no_content
    # end

    # should 'I must not add an existing user to my orga' do
    #   assert_no_difference('@orga.users.count') do
    #     put :add_member, id: @orga.id, user_id: user.id
    #     assert_response :forbidden
    #   end
    # end

    should 'I want to update the data of the orga' do
      desc = @orga.description
      title = @orga.title+'abc123'
      patch :update, params: {
          id: @orga.id,
          meta: {
              trigger_operation: 'update_data'
          },
          data: {
              type: 'orgas',
              id: @orga.id,
              attributes: {
                  title: title
              }
          }
      }
      assert_response :ok
      @orga.reload
      assert_equal @orga.title, title
      assert_equal @orga.description, desc
    end

    should 'I may not update the structure of the orga' do
      patch :update, params: {
          id: @orga.id,
          meta: {
              trigger_operation: 'update_all'
          },
          data: {
              type: 'orgas',
              id: @orga.id,
              attributes: {
                  title: 'newTitle'
              }
          }
      }
      assert_response :forbidden

      patch :update, params: {
          id: @orga.id,
          meta: {
              trigger_operation: 'update_structure'
          },
          data: {
              type: 'orgas',
              id: @orga.id,
              attributes: {
                  title: 'newTitle'
              }
          }
      }
      assert_response :forbidden
    end

    should 'I must not delete my orga' do
      skip 'implement delete'
      assert_no_difference 'Orga.count' do
        process :destroy, methode: :delete, params: { id: @orga.id }
      end
      assert_response :forbidden
    end
  end

  context 'As user' do
    setup do
      @user = User.new
      @orga = Orga.first
      stub_current_user(user: @user)
    end

    # should 'I want a list of all members in an orga, I am not member in orga' do
    #   get :list_members, id: @orga.id
    #   assert_response :forbidden
    # end

    should 'I may not update the data of some orga, I am not member in orga' do
      desc = @orga[:description]
      upd = @orga[:updated_at]
      patch :update, params: {
          id: @orga.id,
          meta: {
              trigger_operation: 'update_data'
          },
          data: {
              type: 'orgas',
              id: @orga.id,
              attributes: {
                  title: 'newTitle'
              }
          }
      }
      assert_response :forbidden
      @orga.reload
      assert_not_equal @orga[:title], 'newTitle'
      assert_equal @orga[:description], desc
      assert_in_delta @orga[:updated_at], upd, 0.0001
    end

    should 'show orga' do
      get :show, params: { id: @orga.id }
      # expected = JSONAPI::ResourceSerializer.new(Api::V1::OrgaResource).serialize_to_hash(Api::V1::OrgaResource.new(@orga, nil)).to_json
      # assert_equal expected, response.body
      #todo above
    end

    should 'I want a list of all orgas' do
      skip 'todo'
      get :index
      assert_response :ok
      expected = ActiveModelSerializers::SerializableResource.new(Orga.all, {}).to_json
      assert_equal expected, response.body
    end

    should 'I must not delete some orga' do
      assert_no_difference 'Orga.count' do
        process :destroy, methode: :delete, params: { id: @orga.id }
      end
      assert_response :forbidden, response.body
    end
  end
end