module Able

  extend ActiveSupport::Concern

  included do
    # INCLUDES
    include StateMachine
    include Translatable
    include Inheritable

    class << self
      def translatable_attributes
        %i(title description short_description)
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
    attr_accessor :skip_short_description_validation

    scope :annotated, -> { joins(:annotations) }
    scope :unannotated,
      -> {
        includes(:annotation_categories).references(:annotation_categories).
          where(annotation_categories: { id: nil })
      }

    # VALIDATIONS
    # validates :contact_infos, presence: true, on: :update
    validates :category, presence: true, on: :update, unless: :skip_all_validations?

    validates :title, presence: true, length: { maximum: 150 }, unless: :skip_all_validations?
    # FIXME: Disabled for testing Todos
    # validates :description, presence: true
    validates :short_description, presence: true, length: { maximum: 350 },
      unless: -> { skip_short_description_validation || skip_all_validations? }

    validates :tags, format: /\A[^\s]+\z/, allow_blank: true, unless: :skip_all_validations?

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
  end

end
