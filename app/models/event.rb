class Event < ApplicationRecord
  include Thing
  include Able

  acts_as_tree(dependent: :restrict_with_exception)
  alias_method :sub_events, :children
  alias_method :parent_event, :parent
  alias_method :parent_event=, :parent=
  alias_method :sub_events=, :children=

end
