require 'test_helper'

class OrgaTest < ActiveSupport::TestCase

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
  end

  context 'with existing orga' do
    setup do
      @orga = Orga.create!(title: 'FirstOrga', description: 'Nothing goes above', parent_orga: Orga.first)
    end

    should 'have contact_informations' do
      assert @orga.contact_info.blank?
      assert contact_info = ContactInfo.create(contactable: @orga)
      assert_equal @orga.reload.contact_info, contact_info
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
  end
end
