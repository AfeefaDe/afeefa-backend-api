ENV['RAILS_ENV'] = 'development'

FactoryGirl.reload

module Dev
  module SetupForConvertActorToOffer

    class << self
      include FactoryGirl::Syntax::Methods
      def setup
        Current.user = User.where(area: 'dresden').last

        title_key = Time.now.strftime("%d.%m.%Y %H:%M:%S")
        actor = create(:orga_without_contacts, title: 'Actor->Offer ' + title_key)

        # old parents
        actor_initiator1 = create(:orga, title: 'Actor->Offer Initiator1 ' + title_key)
        actor.project_initiators << actor_initiator1
        actor_initiator2 = create(:orga, title: 'Actor->Offer Initiator2 ' + title_key)
        actor.project_initiators << actor_initiator2

        # offers, events, projects
        event1 = create(:event, title: 'Actor->Offer Event1 ' + title_key)
        actor.events << event1
        event2 = create(:event, title: 'Actor->Offer Event2 ' + title_key)
        actor.events << event2

        offer1 = create(:offer, title: 'Actor->Offer Offer1 ' + title_key)
        actor.offers << offer1
        offer2 = create(:offer, title: 'Actor->Offer Offer2 ' + title_key)
        actor.offers << offer2

        project1 = create(:orga, title: 'Actor->Offer Project1 ' + title_key)
        actor.projects << project1
        project2 = create(:orga, title: 'Actor->Offer Project2 ' + title_key)
        actor.projects << project2

        # contact, location
        contact = create(:contact, owner: actor, title: 'Actor->Offer Contact ' + title_key)
        location = create(:location, contact: contact, owner: actor, title: 'Actor->Offer Location ' + title_key) # location is owned by this contact
        # link location to contact
        location.linking_contacts << contact
        # link contact to actor
        contact.linking_owners << actor

        # navigation
        navigation_item = DataModules::FeNavigation::FeNavigation.by_area('dresden').last.navigation_items.last
        actor.navigation_items << navigation_item

        # annotations
        annotation1 = Annotation.create!(detail: 'Actor->Offer Annotation1 ' + title_key, entry: actor, annotation_category: AnnotationCategory.first)
        annotation2 = Annotation.create!(detail: 'Actor->Offer Annotation2 ' + title_key, entry: actor, annotation_category: AnnotationCategory.first)
      end

    end
  end
end