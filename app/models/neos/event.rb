module Neos
  class Event < Neos::Entry

    default_scope { where(type: 2) }

  end
end
