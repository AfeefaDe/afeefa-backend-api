class Area < ApplicationRecord

  def self.[](area)
    Area.where(title: area).last
  end

end
