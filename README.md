GETTING STARTED:

bundle install ( install ruby-dev zlib1g-dev liblzma-dev, mysql-client libmysqlclient-dev, libsqlite3-dev)

cp config/database.yml.example config/database.yml

vi config/database.yml
* configure dbname, user, password

rake db:create
rake db:migrate
rake db:seed

for usage of live db dump:
* create db connection for resource defined in database.yml under key 'afeefa'
* import the db dump under db/afeefa_neos_live.sql using mysql

rails s [-p]
