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
    has_many :locations, as: :locatable, dependent: :destroy # attention: overridden in orga
    has_many :contact_infos, as: :contactable, dependent: :destroy

    belongs_to :category, optional: true
    belongs_to :sub_category, class_name: 'Category', optional: true

    # can be removed after migration
    attr_accessor :skip_unset_inheritance
    def skip_unset_inheritance?
      skip_unset_inheritance || false
    end

    scope :by_area, ->(area) { where(area: area) }

    # VALIDATIONS
    validates :title, presence: true, length: { maximum: 150 }
    # FIXME: Disabled for testing Todos
    # validates :description, presence: true
    validates :short_description, presence: true, length: { maximum: 350 },
      unless: -> { skip_short_description_validation? }

    validates :tags, format: /\A[^\s]+\z/, allow_blank: true

    validates :support_wanted_detail, length: { maximum: 350 }

    validate :validate_parent_id, if: -> { parent_id.present? }

    # validations to prevent mysql errors
    validates :media_url, length: { maximum: 1000 }
    validates :media_type, length: { maximum: 255 }
    validates :tags, length: { maximum: 255 }
    validates :area, length: { maximum: 255 }

    validates_uniqueness_of :facebook_id, allow_blank: true
    validates :facebook_id, numericality: { only_integer: true, allow_blank: true }, length: { minimum: 15, maximum: 64, allow_blank: true }

    # HOOKS
    after_create :create_entry!
    before_destroy :deny_destroy_if_associated_objects_present, prepend: true
    after_destroy :destroy_entry

    before_save do
      self.facebook_id.present? || self.facebook_id = nil
    end

    after_commit on: [:create, :update] do
      fapi_client = FapiClient.new
      fapi_client.entry_updated(self)
    end

    after_destroy do
      fapi_client = FapiClient.new
      fapi_client.entry_deleted(self)
    end

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
