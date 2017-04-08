class Api::V1::BaseController < ApplicationController

  include DeviseTokenAuth::Concerns::SetUserByToken
  include JSONAPI::ActsAsResourceController
  include CustomHeaders

  respond_to :json

  before_action :authenticate_api_v1_user!
  before_action :permit_params

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do
    head :unprocessable_entity
  end

  on_server_error do |error|
    # do custom code or debugging here
    # binding.pry
    # pp error
    # pp error.backtrace
  end

##############################

  before_action :find_objects

  private

  def filter_params
    params.fetch(:filter, {}).permit(filter_whitelist + custom_filter_whitelist)
  end

  def filter_whitelist
    raise NotImplementedError, 'Define filter whitelist in your class!'
  end

  def custom_filter_whitelist
    []
  end

  def apply_custom_filter!(attribute, objects)
    objects
  end

  def find_objects
    @objects = self.class.name.to_s.split('::').last.gsub('Controller', '').singularize.constantize.all

    if (filter = filter_params) && filter.respond_to?(:keys) && filter.keys.present?
      filter_params.each do |attribute, filter_criterion|
        if attribute.to_s.in?(filter_whitelist)
          @objects = @objects.where("#{attribute} LIKE ?", "%#{filter_criterion}%")
        elsif attribute.to_s.in?(custom_filter_whitelist)
          @objects = apply_custom_filter!(attribute, @objects)
        end
      end
    end

    @objects
  end

###############################

  # def ensure_host
  #   allowed_hosts = Settings.api.hosts
  #   if (host = request.host).in?(allowed_hosts)
  #     true
  #   else
  #     render(
  #       text: "wrong host: #{host}, allowed: #{allowed_hosts.join(', ')}",
  #       status: :unauthorized
  #     )
  #     false
  #   end
  # end
  #
  # def ensure_protocol
  #   allowed_protocols = Settings.api.protocols
  #   if (protocol = request.protocol.gsub(/:.*/, '')).in?(allowed_protocols)
  #     true
  #   else
  #     render(
  #       text: "wrong protocol: #{protocol}, allowed: #{allowed_protocols.join(', ')}",
  #       status: :unauthorized
  #     )
  #     false
  #   end
  # end

  # def ensure_admin_secret
  #   if params[:admin_secret] == Settings.api.admin_secret
  #     true
  #   else
  #     head :forbidden
  #     false
  #   end
  # end

  def permit_params
    params.try(:[], :data).try(:[], :attributes).try(:delete, :state)
    params.try(:[], :data).try(:[], :relationships).try(:delete, :creator)
  end

  def render_results(operation_results)
    response_doc = create_response_document(operation_results)
    content = response_doc.contents

    if content.blank? || content.key?(:data) && content[:data].nil?
      error =
        JSONAPI::Exceptions::RecordNotFound.new(params[:id].presence || '(id not given)')
      render_errors(error.errors)
    else
      super
    end
  end

  def context
    { current_user: current_api_v1_user }
  end

  def resource_serializer_klass
    @resource_serializer_klass ||= Api::V1::BaseSerializer
  end

  def render_results(operation_results)
    # binding.pry
    super
  end

  def render_errors(errors)
    super
  end

  def serialization_options
    # binding.pry
    super.merge(
      include_linkage_whitelist: %i(create update show index),
      action: params[:action].to_sym)
  end
end
