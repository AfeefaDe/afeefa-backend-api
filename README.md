GETTING STARTED:

cp config/database.yml.example config/database.yml

vi config/database.yml
* dbname, user, password konfigurieren

rake db:create
rake db:migrate
rake db:seed

rails s [-p]
