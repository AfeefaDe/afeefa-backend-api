# All custom exception and error classes should be defined here.
# Attention: Classes which uses errors need to require them via this line at first in file:
# require 'errors'

module Errors
  class CustomDeleteRestrictionError < ActiveRecord::DeleteRestrictionError
    def initialize(message = nil)
      super
      @message = message
    end

    def message
      @message
    end
  end

  class NotPermittedException < Exception
  end
end
