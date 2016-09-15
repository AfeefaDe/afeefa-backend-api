require 'test_helper'

class Orga::Operations::DeleteTest < ActiveSupport::TestCase

  context 'As admin' do
    setup do
      #@admin = User::Create.(params)
      @admin = admin
      @parent_orga = @admin.orgas.first
      @orga = Orga::Operations::CreateSubOrga.(
          {
              current_user: @admin,
              data: {
                  attributes: {
                      parent_id: @parent_orga.id,
                      title: 'deletetestorga',
                      description: 'this orga will be deleted'
                  },
                  type: 'Orga'
              }
          }
      ).model
      @sub_orga = Orga::Operations::CreateSubOrga.(
          {
              current_user: @admin,
              data: {
                  attributes: {
                      parent_id: @orga.id,
                      title: 'deletetestsuborga',
                      description: 'this orga may not be orphaned'
                  },
                  type: 'Orga'
              }
          }
      ).model
    end

    should 'delete an orga' do
      response, operation = Orga::Operations::Delete.run(
          {
              id: @orga.id,
              current_user: @admin,
              data: {
                  type: 'Orga'
              }
          }
      )
      assert response
      assert @parent_orga.id, @sub_orga.parent_id
      assert_includes @parent_orga.reload.sub_orgas, @sub_orga
      assert_equal @parent_orga.id, @sub_orga.reload.parent_id
      # assert @orga.destroyed? #TODO fix why this does not return true
    end
  end
end
