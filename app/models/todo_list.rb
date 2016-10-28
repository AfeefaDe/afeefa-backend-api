class TodoList < Array

  def initialize
    super
    self << Todo.new
  end

  def where(conditions)
    self
  end

end
