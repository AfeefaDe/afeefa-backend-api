class CreateInitialFacets < ActiveRecord::Migration[5.0]
  def up
    facets = [
      {
        title: 'Akteurstyp',
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
              { title: 'Amt / Behörde' },
              { title: 'Schule' },
              { title: 'KiTa' }
            ]
          },
          {
            title: 'Kultureinrichtung',
            items: [
              { title: 'Bibliothek' },
              { title: 'Theater' },
              { title: 'Kino' },
              { title: 'Museum' },
              { title: 'Parks & Gärten' }
            ]
          },
          {
            title: 'Religiöse Einrichtung',
            items: [
              { title: 'Kirche' },
              { title: 'Moschee' },
              { title: 'Synagoge' },
              { title: 'Tempel' }
            ]
          },
          {
            title: 'Sportstätte',
            items: [
              { title: 'Turnhalle' },
              { title: 'Schwimmhalle' },
              { title: 'Fußballplatz' },
              { title: 'Spielplatz' }
            ]
          }
        ]
      },
      {
        title: 'Angebotstypen',
        owners: ['Offer'],
        color: '#9999ff',
        items: [
          'Auskunft',
          {
            title: 'Beratung',
            items: [
              { title: 'Migrationsberatung' },
              { title: 'Rechtsberatung' },
              { title: 'Berufsberatung' },
              { title: 'Sozialberatung' },
              { title: 'Suchtberatung' },
              { title: 'Familienberatung' }
            ]
          },
          {
            title: 'Bildung',
            items: [
              { title: 'Kurs' },
              { title: 'Sprachtreff' },
              { title: 'Lerntreff' },
              { title: 'Nachhilfe' }
            ]
          },
          {
            title: 'Begegnung',
            items: [
              { title: 'Treffpunkt' },
              { title: 'Begegnungscafé' },
              { title: 'Selbsthilfegruppe' }
            ]
          },
          {
            title: 'Begleitung & Unterstützung',
            items: [
              { title: 'Professionelle Betreuung' },
              { title: 'Patenschaften' }
            ]
          },
          {
            title: 'Spenden',
            items: [
              { title: 'Lebensmittel' },
              { title: 'Bekleidung' },
              { title: 'Möbel' }
            ]
          },
          {
            title: 'Sprachdienstleistung',
            items: [
              { title: 'Übersetzung' },
              { title: 'Dolmetschen' }
            ]
          },
          {
            title: 'Selbst aktiv werden',
            items: [
              { title: 'Offene Werkstatt' }
            ]
          }
        ]
      },
      # {
      #   title: 'Themen',
      #   owners: ['Orga', 'Offer', 'Event'],
      #   color: '#e4b100',
      #   items: [
      #     { title: 'Wohnen' },
      #     {
      #       title: 'Hobby',
      #       items: [
      #         { title: 'Kochen' },
      #         { title: 'Gärtnern' },
      #         { title: 'Handarbeit' },
      #         { title: 'Handwerk' },
      #         { title: 'Reparieren' }
      #       ]
      #     },
      #     {
      #       title: 'Alltag',
      #       items: [
      #         { title: 'Einkaufen' },
      #         { title: 'Mobilität' }
      #       ]
      #     },
      #     {
      #       title: 'Diversität',
      #       items: [
      #         { title: 'LGBT*I*' },
      #         { title: 'Inklusion' }
      #       ]
      #     },
      #     {
      #       title: 'Familie',
      #       items: [
      #         { title: 'Kinder' },
      #         { title: 'Partnerschaft' }
      #       ]
      #     },
      #     'Arbeit',
      #     {
      #       title: 'Bildung',
      #       items: [
      #         { title: 'Ausbildung' },
      #         { title: 'Schule' },
      #         { title: 'Studium' }
      #       ]
      #     },
      #     {
      #       title: 'Sprache',
      #       items: [
      #         { title: 'Deutsch' },
      #         { title: 'Fremdsprachen' }
      #       ]
      #     },
      #     'Sport und Erholung',
      #     {
      #       title: 'Gesundheit und Wohlbefinden',
      #       items: [
      #         { title: 'Medizin' },
      #         { title: 'Sucht' },
      #         { title: 'Psychologie' }
      #       ]
      #     },
      #     {
      #       title: 'Engagement & Ehrenamt',
      #     },
      #     'Politik',
      #     'Asyl und Migration',
      #     'Recht',
      #     {
      #       title: 'Religion',
      #       items: [
      #         { title: 'Jüdische Religion' },
      #         { title: 'Christliche Religion' },
      #         { title: 'Islamische Religion' }
      #       ]
      #     },
      #     'Gemeinschaft',
      #     {
      #       title: 'Kultur und Kunst',
      #       items: [
      #         { title: 'Musik' },
      #         { title: 'Theater' },
      #         { title: 'Gestaltung' }
      #       ]
      #     }
      #   ]
      # },
      {
        title: 'Teilnahmekriterien',
        owners: ['Offer', 'Event'],
        color: '#99ccFF',
        items: [
          'Kostenpflichtig',
          'Anmeldung erforderlich',
          'Kinderbetreuung möglich',
          'barrierefrei'
        ]
      },
      {
        title: 'Zielgruppen',
        owners: ['Offer', 'Event'],
        color: '#318b86',
        items: [
          'Frauen',
          'Männer',
          'Kinder',
          'Jugendliche',
          'Familien',
          'Geflüchtete',
          'Ehrenamtliche',
          'LGBT*I*',
          'Multiplikator*innen'
        ]
      },
      {
        title: 'Formate',
        owners: ['Offer', 'Event'],
        color: '#ff9999',
        items: [
          'Vortrag',
          'Diskussion',
          'Treff',
          'Konzert',
          'Film',
          'Lesung',
          'Ausstellung',
          'Kurs',
          'Workshop',
          'Konferenz, Tagung',
          'Fest, Feier, Festival'
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
