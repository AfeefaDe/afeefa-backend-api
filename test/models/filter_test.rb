require 'test_helper'

class FilterTest < ActiveSupport::TestCase

  class MyFilter
    include Filter
  end

  should 'apply filter including multiple keywords in different formats' do
    assert orga = create(:orga, title: 'Garten schmutz', description: 'hallihallo')
    assert orga2 = create(:orga, title: 'Garten FOObar schmutz')

    filter_instance = MyFilter.new
    filter = 'title'
    filter_criterion = 'Garten'
    objects = Orga.all

    # term must be found
    results = filter_instance.send(:apply_filter!, filter, filter_criterion, objects)
    assert_equal 2, results.size
    assert_includes results, orga
    assert_includes results, orga2

    # both terms must be found
    filter_criterion = 'Garten schmutz'
    results = filter_instance.send(:apply_filter!, filter, filter_criterion, objects)
    assert_equal 2, results.size
    assert_includes results, orga
    assert_includes results, orga2

    # both terms must be found
    filter_criterion = %w(Garten schmutz)
    results = filter_instance.send(:apply_filter!, filter, filter_criterion, objects)
    assert_equal 2, results.size
    assert_includes results, orga
    assert_includes results, orga2

    # both terms must be found
    filter_criterion = 'Garten foo'
    results = filter_instance.send(:apply_filter!, filter, filter_criterion, objects)
    assert_equal 1, results.size
    assert_equal orga2, results.last

    # both terms must be found
    filter_criterion = %w(Garten foo)
    results = filter_instance.send(:apply_filter!, filter, filter_criterion, objects)
    assert_equal 1, results.size
    assert_equal orga2, results.last

    # term with space must be found
    filter_criterion = '"Garten schmutz"'
    results = filter_instance.send(:apply_filter!, filter, filter_criterion, objects)
    assert_equal 1, results.size
    assert_equal orga, results.last

    # term with space must be found
    filter_criterion = '"Garten foo"'
    results = filter_instance.send(:apply_filter!, filter, filter_criterion, objects)
    assert_equal 1, results.size
    assert_equal orga2, results.last

    # both terms must be found (for duplicates it is the same like one term)
    filter_criterion = 'Garten Garten'
    results = filter_instance.send(:apply_filter!, filter, filter_criterion, objects)
    assert_equal 2, results.size
    assert_includes results, orga
    assert_includes results, orga2

    # both terms must be found (for duplicates it is the same like one term)
    filter_criterion = %w(Garten Garten)
    results = filter_instance.send(:apply_filter!, filter, filter_criterion, objects)
    assert_equal 2, results.size
    assert_includes results, orga
    assert_includes results, orga2

    # term with space can not be found in any orga
    filter_criterion = '"Garten Garten"'
    results = filter_instance.send(:apply_filter!, filter, filter_criterion, objects)
    assert_equal 0, results.size
  end

end
