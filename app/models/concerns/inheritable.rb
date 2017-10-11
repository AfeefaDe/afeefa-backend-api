module Inheritable

  extend ActiveSupport::Concern

  INHERITABLE_ATTRIBUTES_REGEX =
    /\A(short_description|contact_infos|locations)(\|(short_description|contact_infos|locations))*\z/

  included do
    validates_format_of :inheritance, with: INHERITABLE_ATTRIBUTES_REGEX, allow_blank: true
  end

  def add_inheritance_flag(flag)
    if inheritance.present?
      inheritance << "|#{flag}"
    else
      self.inheritance = "#{flag}"
    end
  end

  private

  def unset_inheritance
    self.inheritance = nil
  end

end
