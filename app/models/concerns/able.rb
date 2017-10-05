module Able

  extend ActiveSupport::Concern

  included do
    # INCLUDES
    include StateMachine
    include Translatable
    include Inheritable

    class << self
      def translatable_attributes
        %i(title short_description)
      end
    end
    # TRANSLATABLE END

    auto_strip_attributes :title, :description, :short_description

    # ATTRIBUTES AND ASSOCIATIONS
    has_many :locations, as: :locatable, dependent: :destroy
    has_many :contact_infos, as: :contactable, dependent: :destroy

    has_many :annotations, as: :entry, dependent: :destroy
    has_many :annotation_categories, through: :annotations

    belongs_to :category, optional: true
    belongs_to :sub_category, class_name: 'Category', optional: true

    # can be removed after migration
    attr_accessor :skip_validations_for_migration
    attr_accessor :skip_unset_inheritance
    def skip_unset_inheritance?
      skip_unset_inheritance || false
    end

    scope :annotated, -> { joins(:annotations) }
    scope :unannotated,
      -> {
        includes(:annotation_categories).references(:annotation_categories).
          where(annotation_categories: { id: nil })
      }
    scope :by_area, ->(area) { where(area: area) }

    # VALIDATIONS
    # validates :contact_infos, presence: true, on: :update
    validates :category, presence: true, on: :update, unless: :skip_all_validations?
    validate :validate_sub_category, if: -> { sub_category_id.present? && !skip_all_validations? }

    validates :title, presence: true, length: { maximum: 150 }, unless: :skip_all_validations?
    # FIXME: Disabled for testing Todos
    # validates :description, presence: true
    validates :short_description, presence: true, length: { maximum: 350 },
      unless: -> { skip_validations_for_migration || skip_all_validations? || skip_short_description_validation? }

    validates :tags, format: /\A[^\s]+\z/, allow_blank: true, unless: :skip_all_validations?

    validates :support_wanted_detail, length: { maximum: 350 }, unless: :skip_all_validations?

    validate :validate_parent_id, if: -> { parent_id.present? }

    # HOOKS
    after_create :create_entry!
    before_destroy :deny_destroy_if_associated_objects_present, prepend: true
    after_destroy :destroy_entry

    def create_entry!
      if is_a?(Orga) && root_orga?
        true
      else
        Entry.create!(entry: self)
      end
    end

    def destroy_entry
      Entry.where(entry: self).destroy_all
    end

    def validate_parent_id
      errors.add(:parent_id, 'Can not be the parent of itself!') if parent_id == id
    end

    def validate_sub_category
      if category_id != sub_category.parent_id
        errors.add(:sub_category, 'Unterkategorie passt nicht zur Hauptkategorie')
      end
    end

    def do_not_skip_short_description_validation!
      @skip_short_description_validation = false
    end

    def skip_short_description_validation!
      @skip_short_description_validation = true
    end

    def skip_short_description_validation?
      @skip_short_description_validation || false
    end
  end

end
