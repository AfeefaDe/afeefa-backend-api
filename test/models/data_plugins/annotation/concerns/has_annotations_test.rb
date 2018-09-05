require 'test_helper'

module DataPlugins::Annotation
  class HasAnnotationsTest < ActiveSupport::TestCase

    setup do
      @annotation_category = AnnotationCategory.create(title: 'Kategorie1')
    end

    [:orga, :event, :offer].each do |entry_factory|

      should "deliver annotations for #{entry_factory}" do
        entry = create(entry_factory)
        assert_equal [], entry.annotations.all

        annotation = Annotation.create(
          annotation_category_id: @annotation_category.id,
          detail: 'Mache das',
          entry: entry
        )

        assert_equal [annotation], entry.annotations.all
      end

      should "deliver annotations by updated_at for #{entry_factory}" do
        entry = create(entry_factory)
        assert_equal [], entry.annotations.all

        annotation = Annotation.create(
          annotation_category_id: @annotation_category.id,
          detail: 'Mache das',
          entry: entry
        )
        annotation2 = Annotation.create(
          annotation_category_id: @annotation_category.id,
          detail: 'Mache das2',
          entry: entry
        )
        annotation3 = Annotation.create(
          annotation_category_id: @annotation_category.id,
          detail: 'Mache das3',
          entry: entry
        )

        ActiveRecord::Base.record_timestamps = false
        now = 10.minutes.from_now
        annotation2.update(updated_at: now)
        ActiveRecord::Base.record_timestamps = true

        assert_equal [annotation2, annotation3, annotation], entry.annotations.all
      end

      should "add annotation for #{entry_factory}" do
        entry = create(entry_factory)

        annotation = entry.save_annotation(ActionController::Parameters.new(
          annotation_category_id: @annotation_category.id,
          detail: 'Mache das',
        ))

        assert_equal [annotation], entry.annotations.all
      end

      should "set creator on add annotation for #{entry_factory}" do
        entry = create(entry_factory)

        annotation = entry.save_annotation(ActionController::Parameters.new(
          annotation_category_id: @annotation_category.id,
          detail: 'Mache das',
        ))

        assert_equal Current.user, annotation.creator
        assert_equal Current.user, annotation.last_editor
      end

      should "fail adding with wrong category for #{entry_factory}" do
        entry = create(entry_factory)

        exception = assert_raises(ActiveRecord::RecordInvalid) {
          annotation = entry.save_annotation(ActionController::Parameters.new(
            annotation_category_id: 999999999,
            detail: 'Mache das',
          ))
        }
        assert_match 'Kategorie existiert nicht.', exception.message
      end

      should "fail adding without category for #{entry_factory}" do
        entry = create(entry_factory)

        exception = assert_raises(ActiveRecord::RecordInvalid) {
          annotation = entry.save_annotation(ActionController::Parameters.new(
            detail: 'Mache das',
          ))
        }
        assert_match 'Kategorie fehlt.', exception.message
      end

      should "update annotation for #{entry_factory}" do
        entry = create(entry_factory)
        annotation_category2 = AnnotationCategory.create(title: 'Kategorie2')

        annotation = Annotation.create(
          annotation_category_id: @annotation_category.id,
          detail: 'Mache das',
          entry: entry
        )

        entry.save_annotation(ActionController::Parameters.new(
          id: annotation.id,
          annotation_category_id: annotation_category2.id,
          detail: 'Mache das jetzt so',
        ))

        assert_equal 1, entry.annotations.count
        annotation = entry.annotations.first
        assert_equal annotation_category2.id, annotation.annotation_category_id
        assert_equal 'Mache das jetzt so', annotation.detail

        entry.save_annotation(ActionController::Parameters.new(
          id: annotation.id,
          detail: 'Mache das jetzt doch nicht so',
        ))

        assert_equal 1, entry.annotations.count
        annotation = entry.annotations.first
        assert_equal 'Mache das jetzt doch nicht so', annotation.detail
      end

      should "set editor on update annotation for #{entry_factory}" do
        entry = create(entry_factory)

        annotation = Annotation.create(
          annotation_category_id: @annotation_category.id,
          detail: 'Mache das',
          entry: entry
        )

        assert_equal Current.user, annotation.last_editor

        user2 = create(:user)
        Current.stubs(:user).returns(user2)
        annotation.update(detail: 'Yeah!!! Getan')

        assert_equal user2, annotation.last_editor
      end

      should "fail update if annotation does not exist for #{entry_factory}" do
        entry = create(entry_factory)
        exception = assert_raises(ActiveRecord::RecordNotFound) {
          entry.save_annotation(ActionController::Parameters.new(
            id: 123456,
            detail: 'Mache das'
          ))
        }
      end

      should "fail update if annotation belongs to different entry for #{entry_factory}" do
        entry = create(entry_factory)
        entry2 = create(entry_factory)
        entry3 = create(:event)

        annotation = Annotation.create(
          annotation_category_id: @annotation_category.id,
          detail: 'Mache das',
          entry: entry
        )

        exception = assert_raises(ActiveRecord::RecordInvalid) {
          entry2.save_annotation(ActionController::Parameters.new(
            id: annotation.id,
            detail: 'Mache das jetzt anders'
          ))
        }
        assert_match 'Eigentümer kann nicht geändert werden.', exception.message

        exception = assert_raises(ActiveRecord::RecordInvalid) {
          entry3.save_annotation(ActionController::Parameters.new(
            id: annotation.id,
            detail: 'Mache das jetzt anders'
          ))
        }
        assert_match 'Eigentümer kann nicht geändert werden.', exception.message
      end

      should "remove annotation for #{entry_factory}" do
        entry = create(entry_factory)

        annotation = Annotation.create(
          annotation_category_id: @annotation_category.id,
          detail: 'Mache das',
          entry: entry
        )

        assert_difference 'Annotation.count', -1 do
          entry.delete_annotation(id: annotation.id)
        end
      end

      should "fail remove annotation if annotation not found for #{entry_factory}" do
        entry = create(entry_factory)

        annotation = Annotation.create(
          annotation_category_id: @annotation_category.id,
          detail: 'Mache das',
          entry: entry
        )

        assert_no_difference 'Annotation.count' do
          exception = assert_raises(ActiveRecord::RecordNotFound) {
            entry.delete_annotation(id: 987989797)
          }
        end

      end

      should "remove annotation if entry gets removed for #{entry_factory}" do
        entry = create(entry_factory)

        annotation = Annotation.create(
          annotation_category_id: @annotation_category.id,
          detail: 'Mache das',
          entry: entry
        )
        annotation2 = Annotation.create(
          annotation_category_id: @annotation_category.id,
          detail: 'Mache das auch noch',
          entry: entry
        )

        assert_difference 'Annotation.count', -2 do
          entry.destroy
        end
      end

    end

  end
end
