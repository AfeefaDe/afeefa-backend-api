require 'test_helper'

class DummyOperationTest < ActiveSupport::TestCase

  setup do
    skip 'only for documentation'
  end

  context 'create a score' do

    should 'persist in db' do
      score = Score::Create.(score: { title: 'schönes Lied', voices: 'SATB', year: '2016' }).model
      assert score.persisted?
      assert_equal 'schönes Lied', score.title
    end

    should 'validate title' do
      res, op = Score::Create.run(score: { title: '', voices: 'SATB', year: '2016' })
      assert_equal false, res
      assert_equal false, op.model.persisted?
      assert_equal ['Bitte geben Sie den Namen des Stückes an!'], op.contract.errors[:title]
    end

  end

end
