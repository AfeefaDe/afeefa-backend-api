class Area < ApplicationRecord

  def self.[](area)
    Area.find_by(title: area)
  end

end
