class StructuresTest < Test::Unit::TestCase

  include Rack::Test::Methods
  
  def app
    Moonrope::Rack::Middleware.new($mr)
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
    get "/api/v1/users/list", :params => params
    assert_equal 200, last_response.status
    assert response_json = JSON.parse(last_response.body)
    assert_equal 'success', response_json['status']
    assert response_json['data'].is_a?(Array)
  end
  
end
