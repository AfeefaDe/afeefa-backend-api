class MigrateDataModuleContact < ActiveRecord::Migration[5.0]

  def do_up_stuff
    create_table :contacts do |t|
      t.references :owner, polymorphic: true, index: true

      t.string :type
      t.string :title
      t.text :web
      t.text :social_media
      t.string :spoken_languages
      t.string :fax

      t.timestamps
    end

    create_table :contact_persons do |t|
      t.references :contact, index: true

      t.string :name
      t.string :role
      t.string :mail
      t.string :phone

      t.timestamps
    end

    create_table :addresses do |t|
      t.references :owner, polymorphic: true, index: true

      t.string :title
      t.string :street
      t.string :zip
      t.string :city
      t.string :lat
      t.string :lon
      t.text :directions

      t.timestamps
    end

    ::ContactInfo.all.each do |contact_info|
      contact = DataPlugins::Contact::Contact.new(
        owner_id: contact_info.contactable_id,
        owner_type: contact_info.contactable_type,
        type: DataPlugins::Contact::Contact::MAIN,
        fax: contact_info.fax,
        social_media: contact_info.social_media,
        spoken_languages: contact_info.spoken_languages,
        web: contact_info.web)
      contact.save(validate: false)
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
    drop_table :contacts
    drop_table :contact_persons
    drop_table :addresses
  end

end
