class RackMiddlewareTest < Test::Unit::TestCase

  include Rack::Test::Methods

  def app
    @app ||= begin
      base = Moonrope::Base.new do
        authenticator :default do
          error "Denied", "No suitable credentials were provided."
          lookup do
            # if there is a x-moonrope-username header, check the auth
            # or raise access denied.
            if request.headers['X-Moonrope-Username']
              if request.headers['X-Moonrope-Username'] == 'user' && request.headers['X-Moonrope-Password'] == 'password'
                User.new(:admin => true)
              else
                error "Denied"
              end
            end
          end
        end
        controller :users do
          action :list do
            # return an empty array
            action { [] }
          end

          action :echo do
            param :name, :required => true
            action { params.name }
          end
        end
      end
      Moonrope::RackMiddleware.new(nil, base)
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
    assert_equal 'application/json', last_response.headers['Content-Type']
    assert last_response.headers['Content-Length']
  end

  def test_params_in_body
    post "/api/v1/users/echo", '{"name":"Adam"}', {'CONTENT_TYPE' => 'application/json'}
    assert_equal 200, last_response.status
    assert response_json = JSON.parse(last_response.body)
    assert_equal 'success', response_json['status']
    assert_equal 'Adam', response_json['data']
  end

  def test_params_in_body_with_charset
    post "/api/v1/users/echo", '{"name":"Adam"}', {'CONTENT_TYPE' => 'application/json; charset=utf8'}
    assert_equal 200, last_response.status
    assert response_json = JSON.parse(last_response.body)
    assert_equal 'success', response_json['status']
    assert_equal 'Adam', response_json['data']
  end

  def test_passing_invalid_json_renders_a_bad_request
    get "/api/v1/users/list", {:params => "{invalidjson}"}
    assert_equal 400, last_response.status
    assert response_json = JSON.parse(last_response.body)
    assert_equal 'invalid-json', response_json['status']
  end

  def test_authenticated_api_methods
    # correct credential
    get "/api/v1/users/list", {}, auth_headers('user', 'password')
    assert response_json = JSON.parse(last_response.body)
    assert_equal 'success', response_json['status']
    # invalid password
    get "/api/v1/users/list", {}, auth_headers('user-invalid', 'password-invalid')
    assert response_json = JSON.parse(last_response.body)
    assert_equal 'error', response_json['status']
    assert_equal 'Denied', response_json['data']['code']
  end

  def test_request_callback_is_invoked
    request_count = 0
    app.base.on_request = Proc.new do |base, env|
      request_count += 1
    end
    assert_equal 0, request_count
    get "/api/v1/users/list"
    assert_equal 1, request_count
    get "/api/v1/users/list"
    assert_equal 2, request_count
  end


  private

  def auth_headers(username, password)
    {'HTTP_X_MOONROPE_USERNAME' => username, 'HTTP_X_MOONROPE_PASSWORD' => password}
  end

end
