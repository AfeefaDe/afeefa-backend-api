class Orga < ApplicationRecord

  ROOT_ORGA_TITLE = 'ROOT-ORGA'
  ROOT_ORGA_DESCRIPTION = 'ROOT-DESCRIPTION'

  # INCLUDES
  include Owner
  include Able
  include Jsonable

  # ATTRIBUTES AND ASSOCIATIONS
  acts_as_tree(dependent: :restrict_with_exception, foreign_key: :parent_orga_id)
  alias_method :sub_orgas, :children
  alias_method :sub_orgas=, :children=
  alias_method :parent_orga, :parent
  alias_method :parent_orga=, :parent=
  alias_attribute :parent_id, :parent_orga_id

  has_many :events
  has_many :resource_items
  has_many :offers
  # has_many :roles, dependent: :destroy
  # has_many :users, through: :roles
  # has_many :admins, -> { where(roles: { title: Role::ORGA_ADMIN }) }, through: :roles, source: :user

  # has_and_belongs_to_many :categories, join_table: 'orga_category_relations'

  # VALIDATIONS
  validate :validate_orga_type_id

  validates_uniqueness_of :title

  validate :add_root_orga_edit_error, if: -> { root_orga? }
  validates_presence_of :parent_id, unless: :root_orga?

  # HOOKS
  before_validation :set_parent_orga_as_default, if: -> { parent_orga.blank? }
  before_validation :unset_inheritance, if: -> { parent_orga.root_orga? && !skip_unset_inheritance? }
  # before_destroy :move_sub_orgas_to_parent, prepend: true

  # SCOPES
  scope :without_root, -> { where(title: nil).or(where.not(title: ROOT_ORGA_TITLE)) }
  default_scope { without_root }

  scope :all_for_ids, -> (ids) {
    includes(Orga.default_includes).
    where(id: ids)
  }

  # DEFAULTS FOR NEW
  after_initialize do |orga|
    if orga.orga_type_id.blank?
      orga.orga_type_id = OrgaType.default_orga_type_id
    end
  end

  # CLASS METHODS
  class << self
    def root_orga
      Orga.unscoped.find_by_title(ROOT_ORGA_TITLE)
    end

    def default_attributes_for_json
      %i(orga_type_id title created_at updated_at state_changed_at active
        count_events count_resource_items).freeze
    end

    def attribute_whitelist_for_json
      (default_attributes_for_json +
        %i(description short_description media_url media_type
            support_wanted support_wanted_detail
            tags certified_sfr inheritance facebook_id)).freeze
    end

    def default_relations_for_json
      %i(initiator annotations category sub_category facet_items creator last_editor).freeze
    end

    def relation_whitelist_for_json
      (default_relations_for_json + %i(resource_items contacts offers) +
        %i(projects project_initiators networks network_members partners)).freeze
    end

    def count_relation_whitelist_for_json
      %i(resource_items events).freeze
    end

    def default_includes
      [
        :category,
        :sub_category,
        :facet_items,
        :creator,
        :last_editor,
        :annotations,
        :resource_items,
        :events,
        :offers,
        :project_initiators,
        :projects,
        :network_members
      ]
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

  def initiator
    self.project_initiators.try(:first)
  end

  def initiator_to_hash
    if initiator
      initiator.to_hash(attributes: ['title'], relationships: nil)
    end
  end

  def contacts_to_hash
    contacts.map { |c| c.to_hash(attributes: c.class.default_attributes_for_json) }
  end

  def resource_items_to_hash
    resource_items.map { |r| r.to_hash(attributes: r.class.default_attributes_for_json) }
  end

  def parent_orga_to_hash
    if parent_orga && !parent_orga.root_orga?
      parent_orga.to_hash
    end
  end

  private

  def validate_orga_type_id
    orga_type = OrgaType.where(id: orga_type_id).first
    errors.add(:orga_type_id, 'Orga Type ist nicht gültig') if !orga_type
  end

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

  # INCLUDE NEW CODE FROM ACTOR
  include DataModules::Actor::Concerns::HasActorRelations
  include DataPlugins::Contact::Concerns::HasContacts
  include DataPlugins::Location::Concerns::HasLocations
  include DataPlugins::Facet::Concerns::HasFacetItems
  include DataModules::Offer::Concerns::HasOffers
  include DataModules::FENavigation::Concerns::HasFENavigationItems

end
