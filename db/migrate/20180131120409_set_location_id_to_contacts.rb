class SetLocationIdToContacts < ActiveRecord::Migration[5.0]
  def up
    ::ContactInfo.all.each do |contact_info|
      location_id = contact_info.contactable.try(:locations).try(:first).try(:id)

      DataPlugins::Contact::Contact.where(owner: contact_info.contactable).update_all(
        location_id: location_id
      )
    end
  end
end
