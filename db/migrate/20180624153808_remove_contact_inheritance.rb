class RemoveContactInheritance < ActiveRecord::Migration[5.0]
  def up
    orgas = Orga.where('inheritance like ?', '%contact_infos%')

    orgas.each do |orga|

      # create missing contacts
      if orga.contacts.count == 0
        if orga.project_initiators.count > 0
          parent = orga.project_initiators.first
          if parent.contacts.count > 0
            parent_contact = parent.contacts.first

            contact = DataPlugins::Contact::Contact.create(
              owner: orga,
              type: DataPlugins::Contact::Contact::MAIN
            )

            contact.update(
              social_media: parent_contact.social_media,
              spoken_languages: parent_contact.spoken_languages,
              web: parent_contact.web,
              opening_hours: parent_contact.opening_hours
            )

            if parent_contact.contact_persons.count > 0
              parent_person = parent_contact.contact_persons.first
              DataPlugins::Contact::ContactPerson.create(
                contact: contact,
                mail: parent_person.mail,
                name: parent_person.name,
                phone: parent_person.phone
              )
            end

          end
        end

      else
        # fill in missing fields
        contact = orga.contacts.first

        if orga.project_initiators.count > 0
          parent = orga.project_initiators.first
          if parent.contacts.count > 0
            parent_contact = parent.contacts.first

            contact.update(
              social_media: contact.social_media || parent_contact.social_media,
              spoken_languages: contact.spoken_languages || parent_contact.spoken_languages,
              web: contact.web || parent_contact.web,
              opening_hours: contact.opening_hours || parent_contact.opening_hours
            )

            if parent_contact.contact_persons.count > 0
              parent_person = parent_contact.contact_persons.first

              if contact.contact_persons.count > 0
                contact_person = contact.contact_persons.first
                contact_person.update(
                  mail: contact_person.mail || parent_person.mail,
                  name: contact_person.name || parent_person.name,
                  phone: contact_person.phone || parent_person.phone
                )
                  else
                DataPlugins::Contact::ContactPerson.create(
                  contact: contact,
                  mail: parent_person.mail,
                  name: parent_person.name,
                  phone: parent_person.phone
                )
              end
            end

          end
        end

      end
    end
  end

  def down
  end
end
