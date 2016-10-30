class Todo
  include ActiveModel::Model

  def id
    1
  end

  def orgas
    Orga.undeleteds.annotateds
  end

  def events
    Event.undeleteds.annotateds
  end
end
