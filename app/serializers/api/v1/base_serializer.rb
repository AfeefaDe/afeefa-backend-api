class Api::V1::BaseSerializer < JSONAPI::ResourceSerializer

  def initialize(operation_results, options = {})
    super
    if serialize_options = options.fetch(:serialization_options, {})
      @include_linkage_whitelist = serialize_options[:include_linkage_whitelist]
      @action = serialize_options[:action]
    end
  end

  def serialize_to_hash(source)
    super
  end

  private

  def relationships_hash(source, include_directives)
    super
  end

  def link_object_to_many(source, relationship, include_linkage)
    # binding.pry
    super(source, relationship, include_linkage?)
  end

  def link_object_to_many(source, relationship, include_linkage)
    # binding.pry
    super(source, relationship, include_linkage?)
  end

  def to_many_linkage(source, relationship)
    # binding.pry if source.class.to_s == 'Api::V1::AnnotationResource'
    super
  end

  def include_linkage?
    # pp "include linkage is #{@action.in?(@include_linkage_whitelist)}"
    @action.in?(@include_linkage_whitelist)
  end

end
