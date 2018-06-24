class RemoveShortDescriptionInheritance < ActiveRecord::Migration[5.0]
  def initialize(name, version)
    super(name, version)

    @copy_info = 'Info: Vererbung entfernt. Automatisch kopiert von Träger: '
    @empty_info = 'Kurzbeschreibung fehlt. Bitte ergänzen.'
    @inheritance_info = 'Info: Vererbung entfernt. Träger-Beschreibung wird nicht mehr automatisch angezeigt.'
  end

  def up
    annotation_category = AnnotationCategory.find_by(title: 'Kurzbeschreibung fehlt')

    # uUpdate annotation category name
    annotation_category.update!(title: 'Kurzbeschreibung')

    # orga: add annotation if short description and inheritance are present
    orgas_with_short_description = Orga.where('short_description is not null and length(short_description) >= 2')
    orgas_with_short_description.each do |orga|
      if orga.inheritance && orga.inheritance.include?('short_description')
        Annotation.create!(
          detail: @inheritance_info,
          entry: orga,
          annotation_category: annotation_category
        )
      end
    end

    orgas_without_short_description = Orga.where('short_description is null or length(short_description) < 2')

    # orga: copy short descriptions if empty and inheritance is set
    orgas_without_short_description.each do |orga|
      if orga.inheritance && orga.inheritance.include?('short_description')
        parent_orga = orga.project_initiators.first
        if parent_orga && parent_orga.short_description
          orga.update!(short_description: parent_orga.short_description)
          Annotation.create!(
            detail: @copy_info + parent_orga.title,
            entry: orga,
            annotation_category: annotation_category
          )
        end
      end
    end

    # orga: add annotation if no short_description is present
    orgas_without_short_description.each do |orga|
      if !orga.inheritance || !orga.inheritance.include?('short_description')
        Annotation.create!(
          detail: @empty_info,
          entry: orga,
          annotation_category: annotation_category
        )
      end
    end

    # event: add annotation if no short_description is present
    events_without_short_description = Event.where('(date_start > now() or date_end > now()) and (short_description is null or length(short_description) < 2)')
    events_without_short_description.each do |event|
      Annotation.create!(
        detail: @empty_info,
        entry: event,
        annotation_category: annotation_category
      )
    end

  end

  def down
    # orga: reset copied short descriptioin + copy annotation
    annotations_for_copy = Annotation.where('detail like ?', "%#{@copy_info}%")
    annotations_for_copy.each do |annotation|
      annotation.entry.update!(short_description: '.')
      annotation.destroy
    end

    # event or orga: reset empty annotation
    annotations_for_copy = Annotation.where('detail like ?', "%#{@empty_info}%")
    annotations_for_copy.each do |annotation|
      annotation.destroy
    end

    # orga: reset inheritance annotation
    annotations_for_copy = Annotation.where('detail like ?', "%#{@inheritance_info}%")
    annotations_for_copy.each do |annotation|
      annotation.destroy
    end

    # reset annotation category name
    AnnotationCategory.find_by(title: 'Kurzbeschreibung')&.update!(title: 'Kurzbeschreibung fehlt')
  end
end
