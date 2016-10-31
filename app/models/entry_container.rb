class EntryContainer
  include ActiveModel::Model

  def id
    1
  end

  def entries
    Event.without_root.undeleted.annotated
    Orga.without_root.undeleted.annotated
  end

end
