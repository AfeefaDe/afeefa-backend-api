class Api::V1::EntriesBaseController < Api::V1::BaseController

  private

  def filter_whitelist
    [:title, :description, :short_description].map(&:to_s).freeze
  end

end
