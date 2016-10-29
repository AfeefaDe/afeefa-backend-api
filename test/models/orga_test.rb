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
      @orga = Orga.new(title: 'FirstOrga', description: 'Nothing goes above')
      @orga.save(validate: false)
    end

    should 'have contact_informations' do
      orga = Orga.first
      assert orga.contact_infos.blank?
      assert contact_info = ContactInfo.create(contactable: orga)
      assert_includes orga.reload.contact_infos, contact_info
    end

    should 'have categories' do
      skip 'fix root-orga vaidation'
      orga = Orga.first
      assert orga.categories.blank?
      assert category = Category.new(title: 'irgendeine komische Kategorie')
      category.orgas << orga
      category.save!
      assert_includes orga.reload.categories, category
    end
  end
end
