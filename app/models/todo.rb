class Todo
  include ActiveModel::Model

  def id
    1
  end

  def orgas
    Orga.undeleted.annotated
  end

  def events
    Event.undeleted.annotated
  end
end
