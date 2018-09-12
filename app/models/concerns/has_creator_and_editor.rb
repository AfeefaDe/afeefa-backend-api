module HasCreatorAndEditor
  extend ActiveSupport::Concern

  included do
    belongs_to :last_editor, class_name: 'User', optional: true
    belongs_to :creator, class_name: 'User', optional: true

    before_create do
      self.creator = Current.user unless self.creator
    end

    before_save do
      self.last_editor = Current.user if Current.user
    end
  end

  def last_editor_to_hash(attributes: nil, relationships: nil)
    last_editor.try(&:to_hash)
  end

  def creator_to_hash(attributes: nil, relationships: nil)
    creator.try(&:to_hash)
  end

end
