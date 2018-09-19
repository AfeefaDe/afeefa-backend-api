module Types
  class ActorType < Types::BaseObject
    # field :type, String, null: false, description: 'type of object, should be orgas'
    field :id, String, null: false, description: 'id of object'

    # field :area, String, null: false, description: 'Where can you find the actor?'
    # field :state, String, null: false, description: 'Is actor active, this means visible at afeefa.de?'
    #
    # field :actor_type, String, null: false, description: 'kind of actor, should be one of [...]'
    # field :title, String, null: false, description: 'title of actor'
    #
    # field :category_id, String, null: false, description: 'category_id of actor'
    #
    # field :media_url, String, null: true, description: 'media_url of actor, could be an url to an image or a youtube video'
    # field :media_type, String, null: true, description: 'type of media_url, should be one of [image, youtube]'
    #
    # field :facebook_id, String, null: true, description: 'facebook_id of this actor'
    #
    # field :support_wanted, String, null: false, description: 'Is this actor looking for support?'
    # field :support_wanted_detail, String, null: true, description: 'detailed description of wanted support'
    #
    # field :for_children, String, null: false, description: 'Does this actor provide offers for children?'
    # field :certified_sfr, String, null: false, description: 'Is this actor certified by SFR?'
    #
    # field :contact_id, String, null: false, description: 'contact_id of this actor'
    # field :contact_spec, String, null: false, description: 'contact_spec of this actor'
    #
    # field :last_editor_id, String, null: false, description: 'last_editor_id of this actor'
    # field :creator_id, String, null: false, description: 'creator_id of this actor'
  end
end
