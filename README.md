GETTING STARTED:

bundle install ( install ruby-dev zlib1g-dev liblzma-dev, mysql-client libmysqlclient-dev, libsqlite3-dev)

cp config/database.yml.example config/database.yml

vi config/database.yml
* dbname, user, password konfigurieren

rake db:create
rake db:migrate
rake db:seed

rails s [-p]
