require 'test_helper'

class OrgaTest < ActiveSupport::TestCase

  should 'has root orga' do
    assert Orga.root_orga, 'root orga does not exist or scope is wrong'
  end

  should 'validate attributes' do
    orga = Orga.new
    assert orga.locations.blank?
    assert_not orga.valid?
    assert orga.errors[:locations].blank?
    assert_match 'muss ausgefüllt werden', orga.errors[:title].first
    assert_match 'muss ausgefüllt werden', orga.errors[:description].first
    orga.description = '-' * 351
    assert_not orga.valid?
    assert_match 'ist zu lang', orga.errors[:description].first

    assert_match 'muss ausgefüllt werden', orga.errors[:category].first
  end

  should 'set initial state for orga' do
    assert Orga.new.inactive?
    assert_equal StateMachine::INACTIVE, Orga.new.state.to_sym
  end

  should 'set root orga as parent if no parent given' do
    orga = build(:orga, parent_orga_id: nil)
    assert orga.save, orga.errors.messages
    assert_equal Orga.root_orga.id, orga.reload.parent_orga_id
  end

  context 'with existing orga' do
    setup do
      @orga = build(:orga, title: 'FirstOrga', description: 'Nothing goes above', parent_orga: Orga.root_orga)
      assert_equal StateMachine::INACTIVE.to_s, @orga.state
      assert @orga.valid?, @orga.errors.messages
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

    should 'have scope which excludes root orga' do
      assert_equal Orga.unscoped.count - 1, Orga.without_root.count
      assert_includes Orga.unscoped, Orga.root_orga
      assert_not_includes Orga.without_root, Orga.root_orga
    end

    should 'soft destroy orga' do
      assert @orga.save
      assert_not @orga.reload.deleted?
      assert_no_difference 'Orga.unscoped.count' do
        assert_difference 'Orga.undeleted.count', -1 do
          @orga.soft_destroy
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
          assert_no_difference 'Orga.unscoped.count' do
            assert_no_difference 'Orga.undeleted.count' do
              exception =
                assert_raise CustomDeleteRestrictionError do
                  @orga.destroy!
                end
              assert_equal 'Ereignisse müssen gelöscht werden', exception.message
            end
          end
        end
      end
      assert_not @orga.reload.deleted?
    end

    should 'soft_destroy orga' do
      @orga.save!
      assert_not @orga.deleted?

      assert_difference 'Orga.undeleted.count', -1 do
        assert_no_difference 'Orga.unscoped.count' do
          assert_no_difference 'Location.count' do
            assert_no_difference 'ContactInfo.count' do
              assert @orga.soft_destroy, @orga.errors.messages
              assert @orga.deleted?
            end
          end
        end
      end
    end

    should 'destroy orga' do
      @orga.save!
      assert @orga.locations.any?
      assert_not @orga.deleted?

      assert_difference 'Orga.undeleted.count', -1 do
        assert_difference 'Orga.unscoped.count', -1 do
          assert_difference 'Location.count', @orga.locations.count * -1 do
            assert_difference 'ContactInfo.count', @orga.contact_infos.count * -1 do
              assert_difference 'AnnotationAbleRelation.count', @orga.annotation_able_relations.count * -1 do
                assert @orga.destroy
              end
            end
          end
        end
      end
    end

    should 'exclude deleted orgas from undeleted scope' do
      assert @orga.save
      assert_not @orga.deleted?
      assert_includes Orga.all, @orga
      assert @orga.soft_destroy
      assert @orga.deleted?
      assert_not_includes Orga.undeleted, @orga
    end
  end

end
