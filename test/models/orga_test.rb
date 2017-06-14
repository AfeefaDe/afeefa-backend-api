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

  should 'render json' do
    orga = create(:orga)
    assert_jsonable_hash(orga)
    assert_jsonable_hash(orga, attributes: orga.class.attribute_whitelist_for_json)
    assert_jsonable_hash(orga,
      attributes: orga.class.attribute_whitelist_for_json,
      relationships: orga.class.relation_whitelist_for_json)
    assert_jsonable_hash(orga, relationships: orga.class.relation_whitelist_for_json)
  end

  should 'validate attributes' do
    parent_orga = create(:orga)
    orga = Orga.new(parent: parent_orga)
    assert orga.locations.blank?
    assert_not orga.valid?
    assert orga.errors[:locations].blank?
    assert_match 'muss ausgefüllt werden', orga.errors[:title].first
    assert_match 'muss ausgefüllt werden', orga.errors[:short_description].first
    # FIXME: validate category
    # assert_match 'muss ausgefüllt werden', orga.errors[:category].first

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

  should 'skip all validations if wanted' do
    orga = Orga.new
    orga.skip_all_validations!
    assert orga.valid?
    assert orga.save
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

  should 'create translation on orga create' do
    skip 'phraseapp deactivated' unless phraseapp_active?
    orga = build(:orga)
    assert_not orga.translation.blank?
    assert orga.translation(locale: 'en').blank?, orga.translation(locale: 'en')
    assert orga.save
    expected = { title: 'an orga', description: 'this is a short description of this orga' }
    assert_equal expected, orga.translation
    assert_equal expected, orga.translation(locale: 'en')
  end

  should 'update translation on orga update' do
    skip 'phraseapp deactivated' unless phraseapp_active?
    orga = create(:orga)
    expected = { title: 'an orga', description: 'this is a short description of this orga' }
    assert_equal expected, orga.translation
    assert_equal expected, orga.translation(locale: 'en')
    assert orga.update(title: 'foo-bar')
    expected = { title: 'foo-bar', description: 'this is a short description of this orga' }
    assert_equal expected, orga.translation
    assert_equal expected, orga.translation(locale: 'en')
  end

  should 'set inheritance to null if no parent orga given' do
    orga1 = create(:orga, parent_orga_id: nil)
    orga2 = create(:orga, parent_orga_id: orga1.id, title: 'neu', inheritance: 'short_description' )

    assert_equal orga1.id, orga2.parent_orga.id
    assert_equal 'short_description', orga2.inheritance

    orga2.parent_orga = nil
    orga2.save

    assert_equal Orga.root_orga.id, orga2.reload.parent_orga_id
    assert_equal nil, orga2.inheritance
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
      assert_equal ['Can not be the parent of itself!'],  @orga.errors[:parent_id]
    end

    should 'have contact_informations' do
      orga = build(:orga, contact_infos: [])
      assert orga.contact_infos.blank?
      assert orga.save
      assert contact_info = create(:contact_info, contactable: orga)
      assert_includes orga.reload.contact_infos, contact_info
    end

    should 'have categories' do
      @orga = build(:orga, category: nil, sub_category: nil)
      @orga.category.blank?
      @orga.sub_category.blank?
      @orga.category = category = create(:category)
      @orga.sub_category = sub_category = create(:sub_category)
      assert @orga.save
      assert_equal category, @orga.reload.category
      assert_equal sub_category, @orga.reload.sub_category
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

    should 'not soft delete orga with associated orga' do
      @orga.save!
      assert @orga.id
      assert sub_orga = create(:orga, parent_id: @orga.id)
      assert_equal @orga.id, sub_orga.parent_id
      assert @orga.reload.sub_orgas.any?
      assert_not @orga.reload.deleted?
      assert_no_difference 'Orga.count' do
        assert_no_difference 'Orga.undeleted.count' do
          exception =
            assert_raise CustomDeleteRestrictionError do
              @orga.destroy!
            end
          assert_equal 'Unterorganisationen müssen gelöscht werden', exception.message
        end
      end
      assert_not @orga.reload.deleted?
    end

    should 'not soft delete orga with associated event' do
      @orga.save!
      assert @orga.id
      assert event = create(:event, orga_id: @orga.id)
      assert_equal @orga.id, event.orga_id
      assert @orga.reload.events.any?
      assert_not @orga.reload.deleted?
      assert_no_difference 'Event.count' do
        assert_no_difference 'Event.undeleted.count' do
          assert_no_difference 'Orga.count' do
            assert_no_difference 'Orga.undeleted.count' do
              exception =
                assert_raise CustomDeleteRestrictionError do
                  @orga.destroy!
                end
              assert_equal 'Events müssen gelöscht werden', exception.message
            end
          end
        end
      end
      assert_not @orga.reload.deleted?
    end
  end

end
