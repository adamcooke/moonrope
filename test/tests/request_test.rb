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

  def test_headers_are_accessible
    base = Moonrope::Base.new
    env = make_rack_env_hash('/api/v1/users/list', {}, {'HTTP_X_EXAMPLE_HEADER' => 'Hello'})
    request = base.request(env)
    assert_equal 'Hello', request.headers['X-Example-Header']
  end

  def test_ip_is_accessible
    base = Moonrope::Base.new
    env = make_rack_env_hash('/api/v1/users/list')
    request = base.request(env)
    assert_equal '127.0.0.1', request.ip
  end

  def test_authenticated_requests
    base = Moonrope::Base.new do
      authenticator :default do
        lookup do
          User.new(:admin => true)
        end
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
    assert_equal User, request.identity.class
    assert_equal false, request.anonymous?
    assert_equal true, request.authenticated?
  end

  def test_authentication_failures
    base = Moonrope::Base.new do
      authenticator :default do
        lookup do
          error :access_denied, "Not permitted"
        end
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
    assert_equal nil, request.identity
    assert_equal true, request.anonymous?
    assert_equal false, request.authenticated?
  end

  def test_requests_which_authenticator_says_are_anonymous
    base = Moonrope::Base.new do
      authenticator :default do
        lookup { nil }
      end
      controller :users do
        action :list do
          action { true }
        end
      end
    end
    request = base.request(make_rack_env_hash('/api/v1/users/list'))
    assert result = request.execute
    assert_equal "success", result.status
    assert_equal nil, request.identity
    assert_equal true, request.anonymous?
    assert_equal false, request.authenticated?
  end

  def test_trying_to_use_invalid_authenticator_raises_error
    base = Moonrope::Base.new do
      authenticator :default do
        lookup do
          User.new(:admin => true)
        end
      end
      controller :users do
        action :list do
          authenticator :blah
          action { true }
        end
      end
    end

    request = base.request(make_rack_env_hash('/api/v1/users/list'))
    assert_raises Moonrope::Errors::MissingAuthenticator do
      request.execute
    end
  end

  def test_raising_errors_from_the_authenticator_lookup
    base = Moonrope::Base.new do
      authenticator :default do
        error 'InvalidToken', 'Token provided is invalid', :attributes => {:token => 'The token looked up'}
        lookup do
          error 'InvalidToken', :token => request.headers['X-Example-Header']
        end
      end
      controller :users do
        action :list do
          action { true }
        end
      end
    end
    request = base.request(make_rack_env_hash('/api/v1/users/list', {}, {"HTTP_X_EXAMPLE_HEADER" => "1234567"}))
    assert result = request.execute
    assert_equal "error", result.status
    assert_equal "InvalidToken", result.data[:code]
    assert_equal "1234567", result.data[:token]
    assert_equal "Token provided is invalid", result.data[:message]
  end

  def test_appropriate_error_is_returned_from_access_checks
    base = Moonrope::Base.new do
      authenticator :default do
        lookup { :admin }
        rule :default, "CustomError", "Must be authenticated as admin user" do
          identity == :anonymous
        end
      end
      controller :users do
        action :list do
          action { true }
        end
      end
    end
    request = base.request(make_rack_env_hash('/api/v1/users/list', {}, {"HTTP_X_EXAMPLE_HEADER" => "1234567"}))
    assert result = request.execute
    assert_equal "error", result.status
    assert_equal "CustomError", result.data[:code]
    assert_equal "Must be authenticated as admin user", result.data[:message]
  end

  def test_appropriate_error_can_be_returned_from_authenticator_error_hash
    base = Moonrope::Base.new do
      authenticator :default do
        lookup { :admin }
        error "CustomError", "Some custom error message override"
        rule :default, "CustomError", "Must be authenticated as admin user" do
          identity == :anonymous
        end
      end
      controller :users do
        action :list do
          action { true }
        end
      end
    end
    request = base.request(make_rack_env_hash('/api/v1/users/list', {}, {"HTTP_X_EXAMPLE_HEADER" => "1234567"}))
    assert result = request.execute
    assert_equal "error", result.status
    assert_equal "CustomError", result.data[:code]
    assert_equal "Some custom error message override", result.data[:message]
  end


end
