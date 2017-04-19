class Api::V1::OrgasController < Api::V1::BaseController

  def filter_whitelist
    %w(title description short_description).freeze
  end

end
