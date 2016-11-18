GETTING STARTED:

cp config/database.yml.example config/database.yml

vi config/database.yml
* dbname, user, password konfigurieren

```
RAILS_ENV=[test|development|production] (default=development)
rake db:create
rake db:migrate
rake db:seed
```

rails s [-p]
