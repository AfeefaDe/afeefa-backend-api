class Api::V1::SessionsController < DeviseTokenAuth::SessionsController

  include CrossOriginHeader

end
