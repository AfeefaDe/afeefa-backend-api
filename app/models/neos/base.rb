module Neos
  class Base < ActiveRecord::Base

    self.abstract_class = true
    establish_connection :afeefa
    self.inheritance_column = 'another_column_than_type'
    self.primary_key = :persistence_object_identifier

  end
end
