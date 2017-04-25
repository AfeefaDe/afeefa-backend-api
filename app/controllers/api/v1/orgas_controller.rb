class Api::V1::OrgasController < Api::V1::EntriesBaseController

  def filter_whitelist
    %w(title description short_description).freeze
  end

end
