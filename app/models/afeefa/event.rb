module Afeefa
  class Event < Entry

    default_scope { where(type: 2) }

  end
end
