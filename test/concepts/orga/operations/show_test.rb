require 'test_helper'

class Orga::Operations::ShowTest < ActiveSupport::TestCase

  context 'As user' do
    setup do
      @admin = admin
      @orga = @admin.orgas.first
    end

    should 'I want the details of one specific orga' do
      op = Orga::Operations::Show.present({id: @orga.id})

      assert_equal @orga.title, op.model.title
      assert_equal @orga.description, op.model.description
    end
  end
end