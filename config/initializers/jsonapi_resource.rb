JSONAPI.configure do |config|
  # custom processor for nested models
  config.default_processor_klass = Api::V1::BaseProcessor

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

# monkey patch for nested models in relationships
JSONAPI::RequestParser.class_eval do
  def parse_to_one_links_object(raw)
    if raw.nil?
      return {
        type: nil,
        id: nil
      }
    end

    if !(raw.is_a?(Hash) || raw.is_a?(ActionController::Parameters)) # ||
        # raw.keys.length != 2 || !(raw.key?('type') && raw.key?('id'))
      fail JSONAPI::Exceptions::InvalidLinksObject.new
    end

    # {
    #   type: unformat_key(raw['type']).to_s,
    #   id: raw['id']
    # }
    raw.merge(
      type: unformat_key(raw['type']).to_s
    ).deep_symbolize_keys
  end

  def parse_to_many_links_object(raw)
    fail JSONAPI::Exceptions::InvalidLinksObject.new if raw.nil?

    links_object = {}
    if raw.is_a?(Array)
      raw.each do |link|
        link_object = parse_to_one_links_object(link)
        links_object[link_object[:type]] ||= []
        links_object[link_object[:type]].push(link_object)#[:id])
      end
    else
      fail JSONAPI::Exceptions::InvalidLinksObject.new
    end
    # binding.pry
    links_object
  end

  # def parse_add_operation(data)
  #   Array.wrap(data).each do |params|
  #     verify_type(params[:type])
  #
  #     data = parse_params(params, creatable_fields)
  #     binding.pry
  #     @operations.push JSONAPI::Operation.new(:create_resource,
  #       @resource_klass,
  #       context: @context,
  #       data: data,
  #       fields: @fields,
  #       include_directives: @include_directives
  #     )
  #   end
  # rescue JSONAPI::Exceptions::Error => e
  #   @errors.concat(e.errors)
  # end
end
