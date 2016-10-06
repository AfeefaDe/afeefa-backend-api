ActiveModelSerializers.config.adapter = :json_api
ActiveModelSerializers.config.key_transform = :underscore # or :camel_lower, default on adapter=json_api is :dash
ActiveModelSerializers.config.jsonapi_resource_type = :singular