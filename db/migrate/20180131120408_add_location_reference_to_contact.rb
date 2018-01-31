class AddLocationReferenceToContact < ActiveRecord::Migration[5.0]

  def do_up_stuff
    add_reference :contacts, :location, index: true
    add_column :contacts, :opening_hours, :string

    DataPlugins::Contact::Contact.delete_all
    DataPlugins::Location::Location.delete_all

    ::ContactInfo.all.each do |contact_info|
      contact = DataPlugins::Contact::Contact.create!(
        owner_id: contact_info.contactable_id,
        owner_type: contact_info.contactable_type,
        location_id: contact_info.contactable.locations.first.try(:id),
        type: DataPlugins::Contact::Contact::MAIN,
        fax: contact_info.fax,
        social_media: contact_info.social_media,
        spoken_languages: contact_info.spoken_languages,
        web: contact_info.web)
      DataPlugins::Contact::ContactPerson.create!(
        contact_id: contact.id,
        mail: contact_info.mail,
        name: contact_info.contact_person,
        phone: contact_info.phone)
    end

    ::Location.all.each do |location|
      DataPlugins::Location::Location.create!(
        owner_id: location.locatable_id,
        owner_type: location.locatable_type,
        title: location.placename,
        street: location.street,
        zip: location.zip,
        city: location.city,
        lat: location.lat,
        lon: location.lon,
        directions: location.directions)
    end
  end

  def up
    do_up_stuff
  end

  def down
    remove_reference :contacts, :location
    remove_column :contacts, :opening_hours
  end

end
