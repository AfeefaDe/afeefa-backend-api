module DataPlugins::Annotation::Concerns::HasAnnotations

  extend ActiveSupport::Concern

  included do
    has_many :annotations, as: :entry, dependent: :destroy
  end

  def save_annotation(params)
    params['entry_id'] = self.id
    params['entry_type'] = self.class.name
    Annotation.save_annotation(params)
  end

  def delete_annotation(params)
    annotation = Annotation.find_by!(id: params[:id], entry: self)
    return annotation.destroy
  end

  def annotations_to_hash
    annotations.map { |a| a.to_hash(attributes: a.class.default_attributes_for_json) }
  end

end
