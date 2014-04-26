class RackRequestTest < Test::Unit::TestCase

  
  def test_validation
    request = $mr.request(make_rack_env_hash('/api/v1/users/list'))
    assert_equal true, request.valid?
    request = $mr.request(make_rack_env_hash('/api/v1/missing/unknown'))
    assert_equal false, request.valid?
  
    request = $mr.request(make_rack_env_hash('/api/v1'))
    assert_equal false, request.valid?
    request = $mr.request(make_rack_env_hash('/api/v1/users'))
    assert_equal false, request.valid?
  end
  
  def test_version
    request = $mr.request(make_rack_env_hash('/api/v0/users/list'))
    assert_equal 1, request.version
    request = $mr.request(make_rack_env_hash('/api/v1/users/list'))
    assert_equal 1, request.version
    request = $mr.request(make_rack_env_hash('/api/v2/users/list'))
    assert_equal 2, request.version
    request = $mr.request(make_rack_env_hash('/api/v100/users/list'))
    assert_equal 100, request.version
  end
  
  def test_controllers_and_actions
    request = $mr.request(make_rack_env_hash('/api/v1/users/list'))
    assert request.controller.is_a?(Moonrope::Controllers::Controller)
    assert_equal :users, request.controller.name
    assert request.action.is_a?(Moonrope::Controllers::Action)
    assert_equal :list, request.action.name
  end
  
  def test_params_are_accessible
    env = make_rack_env_hash('/api/v1/users/list', {'params' => {'page' => 1}})
    request = $mr.request(env)
    assert request.params.is_a?(Moonrope::ParamSet)
    assert_equal '1', request.params.page
  end
  
  def test_actions_can_be_executed
    request = $mr.request(make_rack_env_hash('/api/v1/users/list'))
    assert result = request.execute
    assert result.is_a?(Moonrope::Controllers::ActionResult), "request.action does not return an ActionResult, was a #{result.class}"
  end
  
  def test_headers_are_accessible
    env = make_rack_env_hash('/api/v1/users/list', {}, {'HTTP_X_EXAMPLE_HEADER' => 'Hello'})
    request = $mr.request(env)
    assert_equal 'Hello', request.headers['X-Example-Header']
  end
  
end
