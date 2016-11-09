require 'test_helper'

class OrgaTest < ActiveSupport::TestCase

  should 'has root orga' do
    assert Orga.root_orga, 'root orga does not exist or scope is wrong'
  end

  context 'with new orga' do
    setup do
      @my_orga = Orga.new
    end

    should 'orga attributes' do
      nil_defaults = [:title, :description]
      (nil_defaults).each do |attr|
        assert @my_orga.respond_to?(attr), "orga does not respond to #{attr}"
      end
      nil_defaults.each do |attr|
        assert_equal nil, @my_orga.send(attr)
      end
    end

    should 'set root orga as parent if no parent given' do
      @my_orga.title = 'foo' * 3
      assert_nil @my_orga.parent_orga
      assert @my_orga.save, @my_orga.errors.messages
      assert_equal Orga.root_orga.id, @my_orga.reload.parent_orga_id
    end
  end

  context 'with existing orga' do
    setup do
      @orga = Orga.create!(title: 'FirstOrga', description: 'Nothing goes above', parent_orga: Orga.root_orga)
    end

    should 'have contact_informations' do
      assert @orga.contact_infos.blank?
      assert contact_info = ContactInfo.create(contactable: @orga)
      assert_includes @orga.reload.contact_infos, contact_info
    end

    should 'have categories' do
      assert @orga.category.blank?
      @orga.category = 'irgendeine komische Kategorie'
      assert @orga.category.present?
    end

    should 'deactivate orga' do
      orga = create(:active_orga)
      assert orga.active?
      orga.deactivate!
      assert orga.inactive?
    end

    should 'activate orga' do
      orga = create(:another_orga)
      assert orga.inactive?
      orga.activate!
      assert orga.active?
    end

    should 'have default scope which excludes root orga' do
      assert_equal Orga.unscoped.count - 1, Orga.count
      assert_includes Orga.unscoped, Orga.root_orga
      assert_not_includes Orga.all, Orga.root_orga
    end
  end

end
