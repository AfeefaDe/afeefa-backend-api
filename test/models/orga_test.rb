require 'test_helper'

class OrgaTest < ActiveSupport::TestCase

  should 'has root orga' do
    assert Orga.root_orga, 'root orga does not exist or scope is wrong'
  end

  should 'save invalid orga' do
    assert_difference 'Orga.unscoped.count' do
      assert_difference 'Orga.count' do
        assert Orga.new.save(validate: false)
      end
    end
  end

  should 'create orga triggers fapi cache' do
    FapiClient.any_instance.expects(:entry_updated).with(instance_of(Orga)).at_least_once

    Orga.new.save(validate: false)
  end

  should 'update orga triggers fapi cache' do
    orga = create(:orga)

    FapiClient.any_instance.expects(:entry_updated).with(orga)

    orga.update(certified_sfr: true)
  end

  should 'remove orga triggers fapi cache' do
    orga = create(:orga)

    FapiClient.any_instance.expects(:entry_deleted).with(orga)

    orga.destroy
  end

  should 'render json' do
    orga = create(:orga)
    assert_jsonable_hash(orga)
    assert_jsonable_hash(orga, attributes: orga.class.attribute_whitelist_for_json)
    assert_jsonable_hash(orga,
                         attributes: orga.class.attribute_whitelist_for_json,
                         relationships: orga.class.relation_whitelist_for_json)
    assert_jsonable_hash(orga, relationships: orga.class.relation_whitelist_for_json)

    assert json = JSON.parse(orga.to_json)
    assert json['attributes'].key?('support_wanted_detail')
    assert json['relationships'].key?('resource_items')
  end

  should 'validate length of support_wanted_detail' do
    orga = Orga.new
    orga.valid?
    assert orga.errors[:support_wanted_detail].blank?
    orga.support_wanted_detail = 'x' * 400
    orga.valid?
    assert orga.errors[:support_wanted_detail].any?
  end

  should 'validate sub_category' do
    orga = Orga.new
    orga.valid?
    assert orga.errors[:sub_category].blank?

    orga.sub_category = Category.sub_categories.last
    orga.valid?
    assert_match 'passt nicht', orga.errors[:sub_category].first

    orga.category = Category.main_categories.first
    orga.valid?
    assert_match 'passt nicht', orga.errors[:sub_category].first

    orga.sub_category = Category.main_categories.first.sub_categories.last
    orga.valid?
    assert orga.errors[:sub_category].blank?
  end

  should 'validate attributes' do
    parent_orga = create(:orga)
    orga = Orga.new(parent: parent_orga)
    assert orga.locations.blank?
    assert_not orga.valid?
    assert orga.errors[:locations].blank?
    assert_match 'fehlt', orga.errors[:title].first
    assert_match 'fehlt', orga.errors[:short_description].first
    # FIXME: validate category
    # assert_match 'fehlt', orga.errors[:category].first

    orga.orga_type_id = 100000000
    assert_not orga.valid?
    assert_match 'ist nicht gültig', orga.errors[:orga_type_id].first

    orga.tags = 'foo bar'
    assert_not orga.valid?
    assert_match 'ist nicht gültig', orga.errors[:tags].first
    orga.tags = 'foo,bar'
    orga.valid?
    assert orga.errors[:tags].blank?

    orga.short_description = '-' * 351
    assert_not orga.valid?
    assert_match 'ist zu lang', orga.errors[:short_description].first

    orga.inheritance = [:foo]
    assert_not orga.valid?
    assert_match 'ist nicht gültig', orga.errors[:inheritance].first
    orga.inheritance = [:short_description]
    orga.valid?
    assert_match 'ist nicht gültig', orga.errors[:inheritance].first
    orga.inheritance = 'short_description'
    orga.valid?
    assert orga.errors[:inheritance].blank?
  end

  should 'have no validation on deactivate' do
    orga = create(:orga)
    assert orga.activate!
    orga.title = nil
    orga.short_description = nil
    assert_not orga.valid?
    assert orga.deactivate!
    assert orga.inactive?
  end

  should 'auto strip name and description' do
    orga = Orga.new
    orga.title = '   abc 123   '
    orga.description = '   abc 123   '
    orga.valid?
    assert_equal 'abc 123', orga.title
    assert_equal 'abc 123', orga.description
  end

  should 'set inheritance to null if no parent orga given' do
    orga1 = create(:orga, parent_orga_id: nil)
    orga2 = create(:orga, parent_orga_id: orga1.id, title: 'neu', inheritance: 'short_description')

    assert_equal orga1.id, orga2.parent_orga.id
    assert_equal 'short_description', orga2.inheritance

    orga2.parent_orga = nil
    orga2.save

    assert_equal Orga.root_orga.id, orga2.reload.parent_orga_id
    assert_nil orga2.inheritance
  end

  should 'set root orga as parent if no parent given' do
    orga = build(:orga, parent_orga_id: nil)
    assert orga.save, orga.errors.messages
    assert_equal Orga.root_orga.id, orga.reload.parent_orga_id
  end

  context 'with existing orga' do
    setup do
      @orga = build(:orga, title: 'FirstOrga', description: 'Nothing goes above', parent_orga: Orga.root_orga)
      assert @orga.valid?, @orga.errors.messages
    end

    should 'create and destroy orga' do
      assert_difference 'Orga.count' do
        assert_difference %q|Entry.where(entry_type: 'Orga').count| do
          @orga.save!
        end
      end

      assert_difference 'Orga.count', -1 do
        assert_difference %q|Entry.where(entry_type: 'Orga').count|, -1 do
          @orga.destroy
        end
      end
    end

    should 'validate parent_id' do
      @orga.save!
      @orga.parent_id = @orga.id
      assert_not @orga.valid?
      assert_equal ['Can not be the parent of itself!'], @orga.errors[:parent_id]
    end

    should 'have contact_informations' do
      orga = build(:orga, contact_infos: [])
      assert orga.contact_infos.blank?
      assert orga.save
      assert contact_info = create(:contact_info, contactable: orga)
      assert_includes orga.reload.contact_infos, contact_info
    end

    should 'have categories' do
      orga = build(:orga, category: nil, sub_category: nil)
      orga.category.blank?
      orga.sub_category.blank?
      orga.category = category = create(:category)
      orga.sub_category = sub_category = create(:sub_category, parent_id: category.id)
      assert orga.save
      assert_equal category, orga.reload.category
      assert_equal sub_category, orga.reload.sub_category
    end

    should 'deactivate orga' do
      orga = create(:active_orga)
      assert orga.active?
      orga.deactivate!
      assert orga.inactive?
    end

    should 'create active orga' do
      orga = build(:orga, state: 'active')
      assert orga.active?
      orga.save!
      assert orga.active?
      orga.deactivate!
      assert orga.inactive?
    end

    should 'activate orga2' do
      orga = create(:orga)
      assert orga.inactive?
      orga.update(active: true)
      assert orga.active?
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

    should 'soft delete orga' do
      assert @orga.save
      assert_not @orga.reload.deleted?
      assert_no_difference 'Orga.count' do
        assert_difference 'Orga.undeleted.count', -1 do
          @orga.delete!
        end
      end
      assert @orga.reload.deleted?
    end

  end

  context 'with orga events, offers' do
    should 'remove event host links on remove orga' do
      orga = create(:orga)
      event = create(:event, host: orga)
      event2 = create(:event, host: orga)

      assert_equal 2, orga.events.count
      assert_equal orga, event.hosts.first
      assert_equal orga, event2.hosts.first

      assert_no_difference 'Event.count' do
        assert_difference 'EventHost.count', -2 do
          assert_difference 'Orga.count', -1 do
            orga.destroy!
          end
        end
      end
    end

    should 'remove offer owner links on remove orga' do
      orga = create(:orga)
      offer = create(:offer, actors: [orga.id])
      offer2 = create(:offer, actors: [orga.id])

      assert_equal 2, orga.offers.count
      assert_equal orga, offer.owners.first
      assert_equal orga, offer2.owners.first

      assert_no_difference 'DataModules::Offer::Offer.count' do
        assert_difference 'DataModules::Offer::OfferOwner.count', -2 do
          assert_difference 'Orga.count', -1 do
            orga.destroy!
          end
        end
      end
    end
  end

end
