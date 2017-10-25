class Resource < ApplicationRecord

  include Jsonable

  # ATTRIBUTES AND ASSOCIATIONS
  belongs_to :orga

  has_attached_file :image#, default_url: '/images/question.png'

  # VALIDATIONS
  validates :title, presence: true
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/
  validates_attachment_file_name :image, matches: [/png\Z/, /jpe?g\Z/]
  validates_with AttachmentSizeValidator, attributes: :image, less_than: 3.megabytes
  # validations to prevent mysql errors
  validates :title, length: { maximum: 255 }
  validates :description, length: { maximum: 255 }

  # HOOKS
  # before_save :decode_base64_image
  # before_validation :decode_base64_image

  # CLASS METHODS
  class << self
    def attribute_whitelist_for_json
      default_attributes_for_json.freeze
    end

    def default_attributes_for_json
      %i(name description url).freeze
    end

    def relation_whitelist_for_json
      default_relations_for_json.freeze
    end

    def default_relations_for_json
      %i(orga).freeze
    end
  end

  # def decode_base64_image
  #   if image_data && content_type && original_filename
  #     decoded_data = Base64.decode64(image_data)
  #
  #     data = StringIO.new(decoded_data)
  #     data.class_eval do
  #       attr_accessor :content_type, :original_filename
  #     end
  #
  #     data.content_type = content_type
  #     data.original_filename = File.basename(original_filename)
  #
  #     self.image = data
  #   end
  # end

end
