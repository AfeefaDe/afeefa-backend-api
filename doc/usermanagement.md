## Welche Rechte und Rollen wollen wir unterscheiden?

* manage_all_users? - Liste aller User (area-übergreifend?)
* manage_all_orgas - Liste aller Orgas (area-übergreifend?)
* manage_all_events - Liste aller Events (area-übergreifend?)
* manage_area_users? - Liste aller User innerhalb der area
* manage_area_orgas - Liste aller Orgas innerhalb der area
* manage_area_events - Liste aller Events innerhalb der area
* manage_own_orgas - Eigene Orgas (via m:n-Relation) → Dürfen hier Owner manipuliert werden?
* manage_own_events - Eigene Events (via Eigene Orgas) → Dürfen hier Owner manipuliert werden?
* manage_own_users? - Eigene User (via Eigene Orgas) → Dürfen hier Owner manipuliert werden?

* manage_facettes? - Facettenzuordnungen verwalten? In verschiedenen Reichweiten?

## Objekte

* Orgas
* Events
* Users

## Verwaltungsreichweite

* manage_all
* manage_area
* manage_own

## Potentielle Rollen

* Afeefa-Redaktion (admin): manage_all_orgas, manage_all_events, manage_all_users
* Redaktion Leipzig (area_manager): manage_area_orgas, manage_area_events
* orga_manager: manage_own_orgas, manage_own_events, manage_own_users
* orga_editor: manage_own_events
* facette_manager

## Ergebnis

* manage object of \[TYPE] in \[ALL|AREA] with special properties, e.g. \[FACETTE]
* manage object of \[TYPE] according to definition of rules

* rules: portperty, value
* rule chain: properties, association type \[AND|OR]

* role has permissions
* permission has entity, constraintset, type \[READ, WRITE]
* constraintset has constraints each associated by type \[AND|OR]
* constraint has entity_property, value

super admin 
* users: write

Person vom Gerede e.V. möchte queer-Bereich verwalten.
* queer ist eine Facette vom Typ Thema.
* Redakteur für das Thema "queer" in Dresden.
* Rollenbezeichnung: Themenredakteur

Rolle: entity, write/read

* Entscheidung: Ein User kann nur eine Rolle haben, da wir es intuitiver finden, 
    dem User die passendste Rolle zu geben und idese ggf. näher zu konfigurieren,
    statt mehrere Rollen zu vergeben.
