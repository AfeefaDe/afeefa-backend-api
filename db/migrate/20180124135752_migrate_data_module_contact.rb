include Migrations::DisableUpdatedAt

class MigrateDataModuleContact < ActiveRecord::Migration[5.0]
  def do_up_stuff
    create_table :contacts do |t|
      t.string :title
      t.string :web, limit: 1000
      t.string :social_media, limit: 1000
      t.string :spoken_languages
      t.string :fax
      t.text :opening_hours

      t.references :owner, polymorphic: true, index: false
      t.references :location, index: false
      t.string :location_spec

      t.timestamps
    end

    create_table :contact_persons do |t|
      t.references :contact, index: false

      t.string :name
      t.string :role
      t.string :mail
      t.string :phone

      t.timestamps
    end

    create_table :addresses do |t|
      t.references :owner, polymorphic: true, index: false
      t.references :contact, index: false

      t.string :title
      t.string :street
      t.string :zip
      t.string :city
      t.string :lat
      t.string :lon
      t.text :directions

      t.timestamps
    end

    add_reference :orgas, :contact, after: :area, index: false
    add_column :orgas, :contact_spec, :string, after: :contact_id

    add_reference :events, :contact, after: :area, index: false
    add_column :events, :contact_spec, :string, after: :contact_id

    ::Location.all.each do |location|
      next if location.locatable.blank?

      contact = DataPlugins::Contact::Contact.create(owner: location.locatable)
      # link owner
      without_updated_at do
        location.locatable.update_attribute(:contact_id, contact.id)
      end

      location = DataPlugins::Location::Location.create(
        owner: location.locatable,
        contact: contact,
        title: location.placename,
        street: location.street,
        zip: location.zip,
        city: location.city,
        lat: location.lat,
        lon: location.lon,
        directions: location.directions
      )

      # link location
      contact.update(location: location)
    end

    ::ContactInfo.all.each do |contact_info|
      next if contact_info.contactable.blank?

      contact = DataPlugins::Contact::Contact.where(owner: contact_info.contactable).try(:first)

      unless contact
        contact = DataPlugins::Contact::Contact.create(owner: contact_info.contactable)
        # link contact
        without_updated_at do
          contact_info.contactable.update_attribute(:contact_id, contact.id)
        end
      end

      contact.update(
        fax: contact_info.fax,
        social_media: contact_info.social_media,
        spoken_languages: contact_info.spoken_languages,
        web: contact_info.web,
        opening_hours: contact_info.opening_hours
      )

      if contact_info.mail.present? || contact_info.contact_person.present? || contact_info.phone.present?
        DataPlugins::Contact::ContactPerson.create(
          contact: contact,
          mail: contact_info.mail,
          name: contact_info.contact_person,
          phone: contact_info.phone
        )
      end

      Orga.connection.schema_cache.clear!
      Orga.reset_column_information
      Event.connection.schema_cache.clear!
      Event.reset_column_information
    end

    add_index :contacts, [:owner_type, :owner_id]
    add_index :contacts, :location_id
    add_index :contact_persons, :contact_id
    add_index :addresses, [:owner_type, :owner_id]
    add_index :addresses, :contact_id
    add_index :orgas, :contact_id
    add_index :events, :contact_id
  end

  def up
    do_up_stuff
  end

  def down
    drop_table :addresses
    drop_table :contact_persons
    drop_table :contacts

    remove_column :orgas, :contact_id
    remove_column :orgas, :contact_spec
    remove_column :events, :contact_id
    remove_column :events, :contact_spec
  end
end
