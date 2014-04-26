class EvalEnvironmentTest < Test::Unit::TestCase
  
  def setup
    @auth_user = User.new
    @auth_user.name = 'Admin User'
    @request = FakeRequest.new(:params => {'page' => '1'}, :version => 2, :authenticated_user => @auth_user)
    @environment = Moonrope::EvalEnvironment.new($mr, @request, :accessor1 => 'Hello')
  end
  
  def test_version
    assert_equal 2, @environment.version
  end
  
  def test_params
    assert @environment.params.is_a?(Moonrope::ParamSet)
    assert_equal '1', @environment.params.page
  end
  
  def test_accessors
    assert_equal 'Hello', @environment.accessor1
  end
  
  def test_authenticated_user_access
    assert_equal @auth_user, @environment.auth
  end
  
  def test_setting_variables
    @environment.set(:fruit, 'bananas')
    assert_equal 'bananas', @environment.variables[:fruit]
    assert @environment.reset
    assert !  @environment.variables.keys.include?(:fruit)
  end
  
  def test_structure_access
    structure = @environment.structure(:user, User.new)
    assert structure.is_a?(Hash), "structure was not a Hash, was a #{structure.class}"
  end
  
  def test_errors
    assert_raises Moonrope::Errors::NotFound do
      @environment.error(:not_found, "Page not found")
    end

    assert_raises Moonrope::Errors::AccessDenied do
      @environment.error(:access_denied, "User not authenticated")
    end

    assert_raises Moonrope::Errors::ValidationError do
      @environment.error(:validation_error, [{:field => 'user', :message => 'should not be blank'}])
    end
    
    assert_raises Moonrope::Errors::ParameterError do
      @environment.error(:parameter_error, [{:field => 'page', :message => 'should be present'}])
    end
    
    assert_raises Moonrope::Errors::RequestError do
      @environment.error(:misc_error, "Unknown issue")
    end
  end
  
end

