module ChaptersApi

  extend ActiveSupport::Concern

  def base_path
    Settings.chapters_api_path || 'http://localhost:3010/chapters'
  end

end
