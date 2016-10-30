class Todo
  include ActiveModel::Model

  def id
    1
  end

  def orgas
    Orga.without_root.undeleted.annotated
  end

  def events
    Event.without_root.undeleted.annotated
  end
end
