class Api::V1::TokenValidationsController < DeviseTokenAuth::TokenValidationsController

  include NoCaching

end
