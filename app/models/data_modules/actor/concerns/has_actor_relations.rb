module DataModules::Actor::Concerns::HasActorRelations

  extend ActiveSupport::Concern

  included do
    # ASSOCIATIONS
    has_many :actor_relations_i_have_associated,
      class_name: DataModules::Actor::ActorRelation, foreign_key: 'associating_actor_id', dependent: :destroy
    has_many :actor_relations_that_associated_me,
      class_name: DataModules::Actor::ActorRelation, foreign_key: 'associated_actor_id', dependent: :destroy

    has_many :actors_i_have_associated, through: :actor_relations_i_have_associated, source: :associated_actor
    has_many :actors_that_associated_me, through: :actor_relations_that_associated_me, source: :associating_actor

    # projects

    has_many :project_relations,
      ->() { DataModules::Actor::ActorRelation.project }, class_name: DataModules::Actor::ActorRelation,
      foreign_key: 'associating_actor_id'
    has_many :project_initiators_relations,
      ->() { DataModules::Actor::ActorRelation.project }, class_name: DataModules::Actor::ActorRelation,
      foreign_key: 'associated_actor_id'

    has_many :projects, through: :project_relations, source: :associated_actor
    has_many :project_initiators, through: :project_initiators_relations, source: :associating_actor

    def projects_to_hash(attributes: nil, relationships: nil)
      projects.map(&:to_hash)
    end

    # TODO initiators are part of the actor list resource as well as the item resource
    # The list default is just to load the initiator with its title,
    # but we want to include more initiator details on the item resource.
    # hence, there is a patch of this method in orgas_controller#show
    # which adds more details to the initiator relation than defined here.
    def project_initiators_to_hash(attributes: nil, relationships: nil)
      project_initiators.map { |i| i.to_hash(attributes: ['title'], relationships: nil) }
    end

    # networks

    has_many :network_member_relations,
      ->() { DataModules::Actor::ActorRelation.network }, class_name: DataModules::Actor::ActorRelation,
      foreign_key: 'associating_actor_id'
    has_many :network_relations,
      ->() { DataModules::Actor::ActorRelation.network }, class_name: DataModules::Actor::ActorRelation,
      foreign_key: 'associated_actor_id'

    has_many :networks, through: :network_relations, source: :associating_actor
    has_many :network_members, through: :network_member_relations, source: :associated_actor

    def networks_to_hash(attributes: nil, relationships: nil)
      networks.map(&:to_hash)
    end

    def network_members_to_hash(attributes: nil, relationships: nil)
      network_members.map(&:to_hash)
    end

    # partners

    has_many :partner_relations_i_have_associated,
      ->() { DataModules::Actor::ActorRelation.partner }, class_name: DataModules::Actor::ActorRelation,
      foreign_key: 'associating_actor_id'
    has_many :partner_relations_that_associated_me,
      ->() { DataModules::Actor::ActorRelation.partner }, class_name: DataModules::Actor::ActorRelation,
      foreign_key: 'associated_actor_id'

    has_many :partners_i_have_associated, through: :partner_relations_i_have_associated, source: :associated_actor
    has_many :partners_that_associated_me, through: :partner_relations_that_associated_me, source: :associating_actor

    def partners
      Orga.where(id: partners_i_have_associated.pluck(:id) + partners_that_associated_me.pluck(:id))
    end

    def partners_to_hash(attributes: nil, relationships: nil)
      partners.map(&:to_hash)
    end

    # CLASS METHODS

    @d = self.default_attributes_for_json
    def self.default_attributes_for_json
      (@d + %i(count_projects count_network_members)).freeze
    end

    @c = self.count_relation_whitelist_for_json
    def self.count_relation_whitelist_for_json
      (@c + %i(projects network_members)).freeze
    end

    # # TODO for steve: migrate methods to something like this and build concern for including this ConcernHelpers into included class
    # def self.has_actor_relations_default_attributes
    #   %i(count_projects count_network_members).freeze
    # end
    #
    # def self.has_actor_relations_count_relation_whitelist_for_json
    #   %i(count_projects count_network_members).freeze
    # end

  end

end
