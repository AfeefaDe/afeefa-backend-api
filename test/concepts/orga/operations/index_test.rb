require 'test_helper'

class Orga::Operations::IndexTest < ActiveSupport::TestCase

  context 'As user' do

    should 'I want a list of all orgas' do
      op = Orga::Operations::Index.present({})
      assert_equal Orga.all, op.model
    end

    should 'I want a list of all orgas, paged' do
      op = Orga::Operations::Index.present({page: {number: 2, size: 2}})
      assert_equal Orga.page(2).per(2), op.model
    end
  end
end