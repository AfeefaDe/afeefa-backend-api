JSONAPI.configure do |config|
  config.json_key_format = :underscored_key
  config.route_format = :underscored_key
  # config.resource_cache = Rails.cache
  config.allow_include = true
  config.allow_sort = true
  config.allow_filter = true
  config.top_level_meta_include_record_count = true
  config.top_level_meta_record_count_key = :record_count
  # TODO: pagination
  # config.default_paginator = :paged
  # config.default_page_size = 10
  # config.maximum_page_size = 100
  # config.top_level_meta_include_page_count = true
  # config.top_level_meta_page_count_key = :page_count
end

# monkey patch for translation of attributes in error messages
JSONAPI::Exceptions::ValidationErrors.class_eval do
  def format_key(key)
    I18n.t("api.attributes.#{key}", default: @key_formatter.format(key))
  end
end
