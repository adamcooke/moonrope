class ActionsTest < Test::Unit::TestCase

  def setup
    @base = Moonrope::Base.new
    @controller = Moonrope::Controller.new(@base, :users)
  end

  def test_basic_definition
    action = Moonrope::Action.new(@controller, :list) do 
      description "An example action with a description"
    end
    assert action.is_a?(Moonrope::Action)
    assert_equal :list, action.name
    assert action.description.is_a?(String)
    assert action.description.length > 0
  end
  
  def test_defining_params
    action = Moonrope::Action.new(@controller, :list) do
      param :page, "The page number"
      param :limit, "The maximum results"
    end
    assert action.params.is_a?(Hash)
    assert_equal [:page, :limit], action.params.keys
    assert action.params.values.all? { |p| p.is_a?(Hash) }
  end
  
  def test_access
    action = Moonrope::Action.new(@controller, :list) do
      access { true }
    end
    assert action.access.is_a?(Proc)
    assert_equal true, action.access.call
  end
  
  def test_action
    action = Moonrope::Action.new(@controller, :list) do
      action { true }
    end
    assert action.action.is_a?(Proc)
    assert_equal true, action.action.call
  end
  
  def test_calling_actions
    action = Moonrope::Action.new(@controller, :list) do
      action { [1,2,3,4] }
    end
    assert result = action.execute
    assert result.is_a?(Moonrope::ActionResult)
    assert_equal 'success', result.status
    assert_equal [1,2,3,4], result.data
    assert_equal Float, result.time.class
    assert_equal({}, result.flags)
    assert_equal({}, result.headers)
  end
  
  def test_checking_access
    action = Moonrope::Action.new(@controller, :list) do
      access { auth.is_a?(User) }
    end
    # unauthenticated users will always return false
    assert_equal false, action.check_access
    # authenticated
    authenticated_request = FakeRequest.new(:authenticated_user => User.new)
    assert_equal true, action.check_access(authenticated_request)
  end
  
  def test_checking_access_with_a_default
    base = Moonrope::Base.new do
      default_access do |action|
        auth.is_a?(User)
      end
      
      controller :users do
        action :list do
          action { true }
        end
      end
    end
    
    action = base.controller(:users) / :list
    # unauthenticated request returns false
    assert_equal false, action.check_access
    # authenticated request should return true because it will match the
    # default access block
    authenticated_request = FakeRequest.new(:authenticated_user => User.new)
    assert_equal true, action.check_access(authenticated_request)
  end
  
  def test_structure_method_can_be_called
    # Create a new structure to test with
    user_structure = Moonrope::Structure.new(@base, :user) do
      basic { {:id => o.id, :username => o.username}}
    end
    
    # Create an action which uses this structure
    action = Moonrope::Action.new(@controller, :list) do
      action do 
        user = User.new(:id => 1, :username => 'adamcooke')
        structure user_structure, user
      end
    end
    
    # Test the structure was returned
    assert result = action.execute
    assert result.is_a?(Moonrope::ActionResult), "result is not a ActionResult"
    assert_equal 1, result.data[:id]
    assert_equal 'adamcooke', result.data[:username]
  end
  
  def test_default_params
    action = Moonrope::Action.new(@controller, :default_params_test) do
      param :page, "The page number", :default => 1234
      param :limit, "The maximum number of results"
      action { {:page => params.page, :limit => params.limit} }
    end
    result = action.execute
    assert_equal({'page' => 1234}, action.default_params)
    assert_equal 1234, result.data[:page]
    assert_equal nil, result.data[:limit]
  end
  
  def test_request_is_passed_to_structures
    # Create a structure which has different data for different types of
    # request.
    user_structure = Moonrope::Structure.new(@base, :user) do
      basic { {:username => o.username} }
      restricted do
        condition { auth.admin == true }
        data { {:private_code => o.private_code} }
      end
    end
    
    # Create an action which returns a structure normally
    action = Moonrope::Action.new(@controller, :list) do
      action do 
        user = User.new(:username => 'lucifer', :private_code => 666)
        structure user_structure, user, :full => true
      end
    end
    
    # Authenticated request
    admin_user = User.new(:username => 'admin', :admin => true)
    authenticated_request = FakeRequest.new(:authenticated_user => admin_user)
    assert result = action.execute(authenticated_request)
    assert_equal 666, result.data[:private_code]
    
    # Unauthenticated request
    assert result = action.execute
    assert_equal nil, result.data[:private_code]
  end
  
  def test_before_filters_are_executed
    controller = Moonrope::Controller.new(@base, :users) do
      before { set_flag :before_all, true }      
      before(:other) { set_flag :before_other, true }
      before(:list) { set_flag :before_list, true }
      before(:list, :potato) { set_flag :before_list_and_potato, true }
    end
    
    action = Moonrope::Action.new(controller, :list) do
      action { true }
    end
    
    assert result = action.execute
    assert_equal true, result.flags[:before_all]
    assert_equal true, result.flags[:before_list]
    assert_equal true, result.flags[:before_list_and_potato]
    assert_equal nil, result.flags[:before_other]
  end
  
  def test_result_can_be_expressed_as_a_hash
    action = Moonrope::Action.new(@controller, :list) do
      action { [1,2,3] }
    end
    assert result = action.execute
    assert hash = result.to_hash
    assert hash.is_a?(Hash), "result.to_hash does not return a hash"
    assert_equal 'success', hash[:status]
    assert hash[:time].is_a?(Float)
    assert hash[:flags].is_a?(Hash)
  end
  
  def test_result_can_be_expressed_as_json
    action = Moonrope::Action.new(@controller, :list) do
      action { [1,2,3] }
    end
    assert result = action.execute
    assert json = result.to_json
    assert json.is_a?(String)
  end
  
  def test_that_param_validation_happens_on_executin
    action = Moonrope::Action.new(@controller, :list) do
      param :page, "Page number", :required => true
      action { [1,2,3] }
    end
    assert result = action.execute
    assert_equal 'parameter-error', result.status
  end
  
  def test_actions_params_can_be_validated_for_presence
    action = Moonrope::Action.new(@controller, :list) do
      param :page, "Page number", :required => true
    end
    
    # request without the param
    assert_raises Moonrope::Errors::ParameterError do
      action.validate_parameters(Moonrope::ParamSet.new)
    end
    
    # request with the param
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new('page' => 1))
  end
  
  def test_actions_params_can_be_validated_for_type
    action = Moonrope::Action.new(@controller, :list) do
      param :page, "Page number", :type => Integer
    end
    
    # request with a string valuee
    assert_raises Moonrope::Errors::ParameterError do
      action.validate_parameters(Moonrope::ParamSet.new('page' => 'stringy'))
    end
    
    # request with an integer value
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new('page' => 1))

    # request with an nil value
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new('page' => nil))
  end
  
  def test_actions_params_can_be_validated_for_regex_matches
    action = Moonrope::Action.new(@controller, :list) do
      param :username, "Username", :regex => /\A[a-z]+\z/
    end
    # request with a nil value
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new)
    
    # request with a matching value
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new('username' => 'adam'))
    
    # request with a string valuee
    assert_raises Moonrope::Errors::ParameterError do
      action.validate_parameters(Moonrope::ParamSet.new('username' => 'invalid-username1234'))
    end
  end 
  
  def test_actions_can_raise_errors
    action = Moonrope::Action.new(@controller, :list) do
      action do
        error :not_found, "Something wasn't found"
      end
    end
    assert result = action.execute
    assert_equal "not-found", result.status
    assert_equal({:message => "Something wasn't found"}, result.data)
  end
  
  class DummyError < StandardError; end
  
  def test_catching_external_errors
    @controller.base.register_external_error DummyError do |exp, res|
      res.status = 'dummy-error'
      res.data = {:message => exp.message}
    end
    
    action = Moonrope::Action.new(@controller, :list) do
      action do
        raise DummyError, "Something happened"
      end
    end
    
    assert result = action.execute
    assert_equal 'dummy-error', result.status
    assert_equal({:message => 'Something happened'}, result.data)
  end
  
  class DummyError2 < StandardError; end
  
  def test_non_defined_errors_are_raised
    action = Moonrope::Action.new(@controller, :list) do
      action do
        raise DummyError2, "Something happened"
      end
    end
    assert_raises(DummyError2) { action.execute }
  end
    
end
