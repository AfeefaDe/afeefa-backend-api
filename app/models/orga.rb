class Orga < ApplicationRecord

  ROOT_ORGA_TITLE = 'ROOT-ORGA'
  ROOT_ORGA_DESCRIPTION = 'ROOT-DESCRIPTION'

  # INCLUDES
  include Owner
  include Able
  include Jsonable

  # ATTRIBUTES AND ASSOCIATIONS
  acts_as_tree(dependent: :restrict_with_exception)
  alias_method :sub_orgas, :children
  alias_method :sub_orgas=, :children=
  alias_method :parent_orga, :parent
  alias_method :parent_orga=, :parent=
  alias_attribute :parent_orga_id, :parent_id

  has_many :events
  # has_many :roles, dependent: :destroy
  # has_many :users, through: :roles
  # has_many :admins, -> { where(roles: { title: Role::ORGA_ADMIN }) }, through: :roles, source: :user

  # has_and_belongs_to_many :categories, join_table: 'orga_category_relations'

  # VALIDATIONS
  validate :add_root_orga_edit_error, if: -> { root_orga? }
  validates_presence_of :parent_id, unless: :root_orga?

  # HOOKS
  before_validation :set_parent_orga_as_default, if: -> { parent_orga.blank? }
  # before_destroy :move_sub_orgas_to_parent, prepend: true

  # SCOPES
  scope :without_root, -> { where(title: nil).or(where.not(title: ROOT_ORGA_TITLE)) }
  default_scope { without_root }

  # CLASS METHODS
  class << self
    def root_orga
      Orga.unscoped.find_by_title(ROOT_ORGA_TITLE)
    end
  end

  # INSTANCE METHODS
  # def add_new_member(new_member:, admin:)
  #   admin.can! :write_orga_structure, self, 'You are not authorized to modify the user list of this organization!'
  #   if new_member.belongs_to_orga?(self)
  #     raise UserIsAlreadyMemberException
  #   else
  #     Role.create!(user: new_member, orga: self, title: Role::ORGA_MEMBER)
  #     return new_member
  #   end
  # end

  # def list_members(member:)
  #   member.can! :read_orga, self, 'You are not authorized to access the data of this organization!'
  #   users
  # end

  # def update_data(member:, data:)
  #   member.can! :write_orga_data, self, 'You are not authorized to modify the data of this organization!'
  #   self.update(data)
  # end

  # def change_active_state(admin:, active:)
  #   admin.can! :write_orga_structure, self, 'You are not authorized to modify the state of this organization!'
  #   self.update(active: active)
  # end

  def root?
    root_orga?
  end

  def root_orga?
    title == ROOT_ORGA_TITLE
  end

  def to_hash(only_reference: false, details: false)
    if only_reference
      default_hash
    else
      whitelist =
        %i(title created_at updated_at state_changed_at)
      if details
        whitelist +=
          %i(description media_url media_type support_wanted for_children certified_sfr
            legacy_entry_id migrated_from_neos)
      end
      attributes_hash =
        self.attributes.deep_symbolize_keys.slice(*whitelist).merge(active: state == ACTIVE)
      default_hash.merge(
        # links: {
        #   self: (Rails.application.routes.url_helpers.api_v1_orga_url(self) rescue 'not available')
        # },
        attributes: attributes_hash,
        relationships: {
          annotations: {
            # links: { related: '' },
            data: annotations.map(&:to_hash)
          },
          locations: { data: locations.map(&:to_hash) },
          contact_infos: { data: contact_infos.map(&:to_hash) },
          category: { data: category.try(:to_hash) },
          sub_category: { data: sub_category.try(:to_hash) },
          parent_orga: { data: parent_orga.try(:to_hash, only_reference: true) },
          sub_orgas: { data: sub_orgas.map { |orga| orga.to_hash(only_reference: true) } }
        }
      )
    end
  end

  private

  def set_parent_orga_as_default
    self.parent_orga = Orga.root_orga
  end

  def deny_destroy_if_associated_objects_present
    errors.clear

    if sub_orgas.any?
      errors.add(:sub_orgas, :not_blank)
    end

    if events.any?
      errors.add(:events, :not_blank)
    end

    errors.full_messages.each do |message|
      raise ::CustomDeleteRestrictionError, message
    end
  end

  def move_sub_orgas_to_parent
    sub_orgas.each do |suborga|
      suborga.parent_orga = parent_orga
      suborga.save!
    end
    self.reload
  end

  def add_root_orga_edit_error
    errors.add(:base, 'ROOT ORGA is not editable!')
  end

end
