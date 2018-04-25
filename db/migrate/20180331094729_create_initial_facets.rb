class CreateInitialFacets < ActiveRecord::Migration[5.0]
  def up
    facets = [
      {
        title: 'Organisationstyp',
        owners: ['Orga'],
        color: '#99FF99',
        items: [
          {
            title: 'NGO',
            items: [
              { title: 'Netzwerk, Bündnis' },
              { title: 'Organisation' },
              { title: 'Projekt' },
              { title: 'Verein' },
              { title: 'Initiative' }
            ]
          },
          {
            title: 'Öffentliche Einrichtung',
            items: [
              { title: 'Krankenhaus' },
              { title: 'Polizei' },
              {
                title: 'Amt / Behörde',
                categories: [133]
              }
            ]
          },
          {
            title: 'Gemeinschaft',
            items: [
              { title: 'Wohnprojekt' },
              { title: 'Treffpunkt' }
            ]
          },
          {
            title: 'Kommerziell',
            items: [
              { title: 'Café & Restaurant' },
              { title: 'Restaurant' },
              { title: 'Restaurant' }
            ]
          },
          {
            title: 'Kultureinrichtung',
            items: [
              { title: 'Bibliothek' },
              { title: 'Theater' },
              { title: 'Kino' },
              { title: 'Museum' },
              { title: 'Park, Garten' }
            ]
          },
          'Werkstatt',
          {
            title: 'Religiöse Einrichtung',
            items: [
              { title: 'Kirche' },
              { title: 'Moschee' },
              { title: 'Synagoge' }
            ]
          },
          {
            title: 'Sportstätte',
            items: [
              { title: 'Turnhalle' },
              { title: 'Schwimmhalle' },
              { title: 'Fußballplatz' }
            ]
          }
        ]
      },
      {
        title: 'Angebotstypen',
        owners: ['Offer'],
        color: '#9999ff',
        items: [
          {
            title: 'Beratung',
            categories: [333],
            items: [
              { title: 'Migrationsberatung' },
              { title: 'Rechtsberatung' },
              { title: 'Berufsberatung' },
              {
                title: 'Sozialberatung',
                categories: [290]
              },
              { title: 'Suchtberatung' },
              { title: 'Familienberatung' }
            ]
          },
          'Information',
          {
            title: 'Bildung',
            categories: [325],
            items: [
              { title: 'Kurs' },
              {
                title: 'Staatlicher Kurs',
                categories: [139]
              },
              {
                title: 'Freier Kurs',
                categories: [138]
              },
              {
                title: 'Sprachtreff',
                categories: [140]
              },
              { title: 'Lerntreff' },
              { title: 'Nachhilfe' }
            ]
          },
          'Begegnung',
          {
            title: 'Begleitung & Unterstützung',
            items: [
              { title: 'Patenschaften' }
            ]
          },
          'Betreuung',
          {
            title: 'Spenden',
            items: [
              { title: 'Lebensmittel' },
              { title: 'Bekleidung' },
              { title: 'Möbel' }
            ]
          },
          'Übersetzungen'
        ]
      },
      {
        title: 'Themen',
        owners: ['Orga', 'Offer', 'Event'],
        color: '#e4b100',
        items: [
          {
            title: 'Wohnen',
            categories: [276]
          },
          {
            title: 'Hobby',
            items: [
              { title: 'Kochen' },
              { title: 'Gärtnern' },
              { title: 'Handarbeit' },
              { title: 'Handwerk' },
              { title: 'Reparieren' }
            ]
          },
          {
            title: 'Alltag',
            items: [
              { title: 'Einkaufen' },
              { title: 'Mobilität' }
            ]
          },
          {
            title: 'Diversität',
            items: [
              { title: 'LGBT*I*' },
              { title: 'Inklusion' }
            ]
          },
          {
            title: 'Familie',
            categories: [284],
            items: [
              {
                title: 'Kinder',
                categories: [326]
              },
              { title: 'Partnerschaft' }
            ]
          },
          'Arbeit',
          {
            title: 'Bildung',
            categories: [331, 147],
            items: [
              { title: 'Ausbildung' },
              {
                title: 'Schule',
                categories: [326]
              },
              { title: 'Studium' }
            ]
          },
          {
            title: 'Sprache',
            categories: [137],
            items: [
              { title: 'Deutsch' },
              { title: 'Fremdsprachen' }
            ]
          },
          'Sport und Erholung',
          {
            title: 'Gesundheit und Wohlbefinden',
            items: [
              { title: 'Medizin' },
              { title: 'Sucht' },
              { title: 'Psychologie' }
            ]
          },
          {
            title: 'Engagement & Ehrenamt',
            categories: [328]
          },
          'Politik',
          'Asyl und Migration',
          'Recht',
          {
            title: 'Religion',
            categories: [269],
            items: [
              { title: 'Jüdische Religion' },
              { title: 'Christliche Religion' },
              { title: 'Islamische Religion' }
            ]
          },
          'Gemeinschaft',
          {
            title: 'Kultur und Kunst',
            items: [
              { title: 'Musik' },
              { title: 'Theater' },
              { title: 'Gestaltung' }
            ]
          }
        ]
      },
      {
        title: 'Teilnahmebedingungen',
        owners: ['Offer', 'Event'],
        color: '#99ccFF',
        items: [
          'Kostenpflichtig',
          'Anmeldung erforderlich',
          {
            title: 'Sprachlevel',
            items: [
              { title: 'A1' },
              { title: 'A2' },
              { title: 'B1' },
              { title: 'B2' }
            ]
          },
        ]
      },
      {
        title: 'Zielgruppen',
        owners: ['Offer', 'Event'],
        color: '#318b86',
        items: [
          'Kinder',
          'Frauen',
          'Jugendliche',
          'Männer',
          'Geflüchtete',
          'Ehrenamtliche',
          'Familien',
          'LGBT*I*'
        ]
      },
      {
        title: 'Veranstaltungsformate',
        owners: ['Offer', 'Event'],
        color: '#ff9999',
        items: [
          'Vortrag',
          'Diskussion',
          'Begegnung',
          'Film',
          'Kurs',
          'Fest, Feier, Festival',
          'Konferenz, Tagung',
          'Unterricht',
          'Workshop',
          {
            title: 'Kulturveranstaltung',
            items: [
              { title: 'Ausstellung' },
              { title: 'Konzert' },
              { title: 'Performance' }
            ]
          }
        ]
      }
    ]

    facets.each do |facet_config|
      facet = DataPlugins::Facet::Facet.create(
        title: facet_config[:title],
        color: facet_config[:color]
      )

      facet_config[:owners].each do |owner_type|
        DataPlugins::Facet::FacetOwnerType.create(
          facet: facet,
          owner_type: owner_type
        )
      end

      facet_config[:items].each do |item|
        title = ''
        categories = nil
        if item.is_a?(Hash)
          title = item[:title]
          categories = item[:categories]
        else
          title = item
        end

        facet_item = DataPlugins::Facet::FacetItem.create(
          title: title,
          facet: facet
        )

        # We do not want to create any facet owners automatically!
        # if categories
        #   orgas = Orga.where(category_id: categories).or(Orga.where(sub_category_id: categories))
        #   orgas.each do |orga|
        #     DataPlugins::Facet::FacetItemOwner.create(
        #       owner: orga,
        #       facet_item: facet_item
        #     )
        #   end
        # end

        if item.is_a?(Hash) && item[:items].present?
          item[:items].each do |sub_item|
            title = ''
            categories = nil
            if sub_item.is_a?(Hash)
              title = sub_item[:title]
              categories = sub_item[:categories]
            else
              title = sub_item
            end

            sub_facet_item = DataPlugins::Facet::FacetItem.create(
              title: title,
              facet: facet,
              parent: facet_item
            )

            # We do not want to create any facet owners automatically!
            # if categories
            #   orgas = Orga.where(category_id: categories).or(Orga.where(sub_category_id: categories))
            #   orgas.each do |orga|
            #     DataPlugins::Facet::FacetItemOwner.create(
            #       owner: orga,
            #       facet_item: sub_facet_item
            #     )
            #   end
            # end

          end
        end
      end
    end
  end

  def down
    DataPlugins::Facet::Facet.destroy_all
  end
end
