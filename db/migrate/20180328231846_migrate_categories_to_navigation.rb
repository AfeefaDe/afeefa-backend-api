class MigrateCategoriesToNavigation < ActiveRecord::Migration[5.0]
  def up
    ['leipzig', 'bautzen', 'dresden'].each do |area|
      navigation = DataModules::FeNavigation::FeNavigation.create(
        area: area
      )
      Category.by_area(area).main_categories.each do |category|
        navigation_item = DataModules::FeNavigation::FeNavigationItem.create(
          navigation: navigation,
          title: key_to_title(category.title),
          color: key_to_color(category.title),
          icon: key_to_icon(category.title)
        )

        Orga.where(category_id: category.id).each do |orga|
          DataModules::FeNavigation::FeNavigationItemOwner.create(
            navigation_item: navigation_item,
            owner: orga
          )
        end

        Event.where(category_id: category.id).each do |event|
          DataModules::FeNavigation::FeNavigationItemOwner.create(
            navigation_item: navigation_item,
            owner: event
          )
        end

        category.sub_categories.each do |sub_category|
          sub_navigation_item = DataModules::FeNavigation::FeNavigationItem.create(
            navigation: navigation,
            parent: navigation_item,
            title: key_to_title(sub_category.title),
            icon: key_to_icon(sub_category.title)
          )

          Orga.where(sub_category_id: sub_category.id).each do |orga|
            DataModules::FeNavigation::FeNavigationItemOwner.create(
              navigation_item: sub_navigation_item,
              owner: orga
            )
          end

          Event.where(sub_category_id: sub_category.id).each do |event|
            DataModules::FeNavigation::FeNavigationItemOwner.create(
              navigation_item: sub_navigation_item,
              owner: event
            )
          end

        end
      end
    end

  end

  def down
    DataModules::FeNavigation::FeNavigation.destroy_all
  end

  def key_to_color(key)
    gray50 = '#999999'
    yellow = '#E4B100'
    red = '#A21C15'
    blue_dark = '#085272'
    olive = '#5E6823'
    turquoise = '#318B86'
    violet = '#693E75'
    orange = '#CA7311'
    olive = '#5E6823'
    blue_dark = '#085272'

    colors = {
      'general': gray50,
      'language': yellow,
      'medic': red,
      'jobs': blue_dark,
      'consultation': olive,
      'leisure': turquoise,
      'community': violet,
      'donation': orange,
      'advice-and-support': olive,
      'living-in-leipzig': yellow,
      'work-and-education': blue_dark
    }

    colors[key.to_sym]
  end

  def key_to_icon(key)
    icons = [
      'general',
      'language',
      'medic',
      'jobs',
      'consultation',
      'leisure',
      'community',
      'donation',
      'external-event',

      'wifi',
      'jewish',
      'christian',
      'islam',
      'religious-other',
      'shop',
      'nature',
      'authority',
      'hospital',
      'police',
      'public-transport',

      'german-course',
      'german-course-state',
      'meet-and-speak',
      'learning-place',
      'interpreter',
      'foreign-language',

      'medical-counselling',
      'psychological-counselling',

      'job-counselling',
      'education-counselling',
      'political-education',
      'library',

      'asylum-counselling',
      'legal-advice',
      'social-counselling',
      'family-counselling',
      'volunteer-coordination',

      'youth-club',
      'sports',
      'museum',
      'music',
      'stage',
      'craft-art',
      'workspace',
      'gardening',
      'cooking',
      'festival',
      'lecture',
      'film',
      'congress',

      'welcome-network',
      'meeting-place',
      'childcare',
      'workshop',
      'sponsorship',
      'lgbt',
      'housing-project',

      'food',
      'clothes',
      'furniture',

      'iwgr',
      'fb-event',

      'hotspots',
      'advice-and-support',
      'living-in-leipzig',
      'work-and-education'
    ]

    icons.include?(key) ? key : nil
  end

  def key_to_title(key)
    categories = {
      'asylum-counselling': 'Migrationsberatung',
      'authority': 'Behörden',
      'childcare': 'Kinderbetreuung',
      'christian': 'Christliche Gemeinschaft',
      'clothes': 'Kleidung',
      'community': 'Gemeinschaft',
      'congress': 'Kongresse + Messen',
      'consultation': 'Beratung',
      'cooking': 'Kochen',
      'craft-art': 'Handwerk + Kunst',
      'donation': 'Spenden',
      'education-counselling': 'Bildungsberatung',
      'education-sponsorship': 'Bildungsunterstützung',
      'eventseries': 'Veranstaltungsreihe',
      'external-event': 'integrierte Daten',
      'family-counselling': 'Familienberatung',
      'fb-event': 'facebook Event',
      'festival': 'Fest',
      'film': 'Film',
      'food': 'Lebensmittel',
      'foreign-language': 'Fremdsprachen',
      'furniture': 'Möbel',
      'gardening': 'Garten',
      'general': 'Allgemeines',
      'german-course': 'freier Deutschkurs',
      'german-course-state': 'staatlicher Deutschkurs',
      'hospital': 'Krankenhaus',
      'housing-project': 'Wohnprojekte',
      'interpreter': 'Übersetzer/ Dolmetscher',
      'islam': 'Islamische Gemeinschaft',
      'iwgr': 'Internationale Wochen gegen Rassismus',
      'jewish': 'Jüdische Gemeinschaft',
      'job-counselling': 'Berufsberatung',
      'jobs': 'Arbeit + Bildung',
      'language': 'Sprache',
      'learning-place': 'Lernort',
      'lecture': 'Vortrag',
      'legal-advice': 'Rechtsberatung',
      'leisure': 'Freizeit',
      'lgbt': 'LGBT',
      'library': 'Bibliothek',
      'medic': 'Gesundheit',
      'medical-care': 'Medizinische Versorgung',
      'medical-counselling': 'Medizinische Beratung',
      'meet-and-speak': 'Sprachtreff',
      'meeting-place': 'Treffpunkt',
      'museum': 'Museum',
      'music': 'Musik',
      'nature': 'Parks + Gärten',
      'other': 'Sonstige',
      'police': 'Polizei',
      'political-education': 'Politische Bildung',
      'psychological-counselling': 'Psychologische Beratung',
      'public-transport': 'Haltestelle',
      'religious-other': 'Religiöse Einrichtung',
      'shop': 'Interkultureller Einkaufsladen',
      'social-counselling': 'Sozialberatung',
      'sponsorship': 'Patenschaften',
      'sports': 'Sport',
      'stage': 'Bühne',
      'swimming': 'Schwimmen',
      'tandem': 'Tandem',
      'tram': 'Straßenbahn',
      'volunteer-coordination': 'Ehrenamtskoordination',
      'welcome-network': 'Willkommensbündnis',
      'wifi': 'Kostenloses WLAN',
      'women-counselling': 'Frauenberatung',
      'workshop': 'Workshop',
      'workspace': 'Räume + Werkstätten',
      'youth-club': 'Jugendtreff',

      # LEIPZIG
      'hotspots': 'Hot Spots',
      'social-advice': 'Sozialberatung',
      'advice-and-support': 'Rat und Begleitung',
      'buddy-programme': 'Patenschaften',
      'daily-life': 'Alltag',
      'family': 'Kinder, Familie & Co',
      'health': 'Gesundheit',
      'housing': 'Wohnen',
      'kita-and-school': 'Kindergarten und Schule',
      'learning-german': 'Deutsch lernen',
      'living-in-leipzig': 'Leben in Leipzig',
      'mobility': 'Mobil sein',
      'participate': 'Mitwirken und sich einmischen',
      'religion': 'Religion',
      'work-and-education': 'Bildung + Arbeit',
      'work-learn-study': 'Arbeit, Ausbildung, Studium'
    }

    categories[key.to_sym] || key
  end
end
