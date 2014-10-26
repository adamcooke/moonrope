class RequestTest < Test::Unit::TestCase


  def test_validation
    # Create a simple API server with just the users & list controller
    base = Moonrope::Base.new do
      controller :users do
        action :list
      end
    end

    request = base.request(make_rack_env_hash('/api/v1/users/list'))
    assert_equal true, request.valid?
    request = base.request(make_rack_env_hash('/api/v1/missing/unknown'))
    assert_equal false, request.valid?

    request = base.request(make_rack_env_hash('/api/v1'))
    assert_equal false, request.valid?
    request = base.request(make_rack_env_hash('/api/v1/users'))
    assert_equal false, request.valid?
  end

  def test_version
    base = Moonrope::Base.new
    request = base.request(make_rack_env_hash('/api/v0/users/list'))
    assert_equal 1, request.version
    request = base.request(make_rack_env_hash('/api/v1/users/list'))
    assert_equal 1, request.version
    request = base.request(make_rack_env_hash('/api/v2/users/list'))
    assert_equal 2, request.version
    request = base.request(make_rack_env_hash('/api/v100/users/list'))
    assert_equal 100, request.version
  end

  def test_controllers_and_actions
    base = Moonrope::Base.new do
      controller :users do
        action :list
      end
    end
    request = base.request(make_rack_env_hash('/api/v1/users/list'))
    assert request.controller.is_a?(Moonrope::Controller)
    assert_equal :users, request.controller.name
    assert request.action.is_a?(Moonrope::Action)
    assert_equal :list, request.action.name
  end

  def test_params_are_accessible
    env = make_rack_env_hash('/api/v1/users/list', {'params' => {'page' => 1}})
    request = Moonrope::Base.new.request(env)
    assert request.params.is_a?(Moonrope::ParamSet)
    assert_equal '1', request.params.page
  end

  def test_actions_can_be_executed
    base = Moonrope::Base.new do
      controller :users do
        action :list do
          action { true }
        end
      end
    end

    request = base.request(make_rack_env_hash('/api/v1/users/list'))
    assert result = request.execute
    assert result.is_a?(Moonrope::ActionResult), "request.action does not return an ActionResult, was a #{result.class}"
  end

  def test_authenticated_requests
    base = Moonrope::Base.new do
      authenticator do
        User.new(:admin => true)
      end
      controller :users do
        action :list do
          action { true }
        end
      end
    end
    # authenticated
    request = base.request(make_rack_env_hash('/api/v1/users/list'))
    assert result = request.execute
    assert_equal User, request.authenticated_user.class
    assert_equal false, request.anonymous?
    assert_equal true, request.authenticated?
  end

  def test_authentication_failures
    base = Moonrope::Base.new do
      authenticator do
        error :access_denied, "Not permitted"
      end

      controller :users do
        action :list do
          action { true}
        end
      end
    end
    request = base.request(make_rack_env_hash('/api/v1/users/list'))
    assert result = request.execute
    assert_equal "access-denied", result.status
    assert_equal nil, request.authenticated_user
    assert_equal true, request.anonymous?
    assert_equal false, request.authenticated?
  end

  def test_requests_which_authenticator_says_are_anonymous
    base = Moonrope::Base.new do
      authenticator { nil }
      controller :users do
        action :list do
          action { true }
        end
      end
    end
    request = base.request(make_rack_env_hash('/api/v1/users/list'))
    assert result = request.execute
    assert_equal "success", result.status
    assert_equal nil, request.authenticated_user
    assert_equal true, request.anonymous?
    assert_equal false, request.authenticated?
  end

  def test_headers_are_accessible
    base = Moonrope::Base.new
    env = make_rack_env_hash('/api/v1/users/list', {}, {'HTTP_X_EXAMPLE_HEADER' => 'Hello'})
    request = base.request(env)
    assert_equal 'Hello', request.headers['X-Example-Header']
  end

end
