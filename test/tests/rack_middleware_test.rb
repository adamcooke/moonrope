class RackMiddlewareTest < Test::Unit::TestCase

  include Rack::Test::Methods
  
  def app
    @app ||= begin
      base = Moonrope::Base.new do
        authenticator do
          # if there is a x-moonrope-username header, check the auth
          # or raise access denied.
          if request.headers['X-Moonrope-Username']
            if request.headers['X-Moonrope-Username'] == 'user' && request.headers['X-Moonrope-Password'] == 'password'
              User.new(:admin => true)
            else
              error :access_denied, "No suitable credentials were provided."
            end
          end
        end
        
        controller :users do
          action :list do
            # ensure that the auth is a user in order to access this request
            access { auth.is_a?(User) }
            # return an empty array
            action { [] }
          end
        end
      end
      Moonrope::Rack.new(base)
    end
  end
  
  def test_non_api_requests_404
    get "/"
    assert_equal 404, last_response.status
  end
  
  def test_api_request_validation
    get "/api/"
    assert_equal 400, last_response.status
    get "/api/v1"
    assert_equal 400, last_response.status
    get "/api/v1/controller"
    assert_equal 400, last_response.status    
  end
  
  def test_api_methods
    params = {:page => 1}.to_json
    get "/api/v1/users/list", {:params => params}
    assert_equal 200, last_response.status
    assert response_json = JSON.parse(last_response.body)
    assert_equal 'success', response_json['status']
    assert response_json['data'].is_a?(Array)
  end
  
  def test_authenticated_api_methods
    # correct credential
    get "/api/v1/users/list", {}, auth_headers('user', 'password')
    assert response_json = JSON.parse(last_response.body)
    assert_equal 'success', response_json['status']
    # invalid password
    get "/api/v1/users/list", {}, auth_headers('user-invalid', 'password-invalid')
    assert response_json = JSON.parse(last_response.body)
    assert_equal 'access-denied', response_json['status']    
  end
  
  private
  
  def auth_headers(username, password)
    {'HTTP_X_MOONROPE_USERNAME' => username, 'HTTP_X_MOONROPE_PASSWORD' => password}
  end
  
end
