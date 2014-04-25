class ActionsTest < Test::Unit::TestCase
  
  def setup
    @controller = $mr.controller(:users)
    @action = @controller.actions[:list]
  end

  def test_basic_definition
    assert @action.is_a?(Moonrope::Controllers::Action)
    assert_equal :list, @action.name
    assert @action.description
    assert @action.description.length > 0
  end
  
  def test_params
    assert @action.params.is_a?(Hash), "Action#params is not an hash"
  end
  
  def test_access
    assert @action.access.is_a?(Proc)
  end
  
  def test_action
    assert @action.action.is_a?(Proc)
  end
  
  def test_calling_actions
    params = Moonrope::ParamSet.new('page' => 3)
    assert result = @action.execute(params)
    assert result.is_a?(Moonrope::Controllers::ActionResult), "result is not a ActionResult"
    assert result.data.is_a?(Array), "result.data is not an array"
    assert result.flags.is_a?(Hash), "result.flags is not a hash"
    assert result.flags[:pagination], "result.flags[:pagination] is not a hash"
    assert_equal 3, result.flags[:pagination][:page]
    assert_equal 'success', result.status
    assert result.headers.is_a?(Hash)
  end
  
  def test_checking_access
    Moonrope.globals(:auth => "Just a string") do
      assert_equal false, @action.check_access
    end
    
    Moonrope.globals(:auth => User.new) do 
      assert_equal true, @action.check_access
    end
  end
  
  def test_check_structures
    @action = @controller.actions[:info]
    assert result = @action.execute
    assert result.is_a?(Moonrope::Controllers::ActionResult), "result is not a ActionResult"
    assert_equal 1, result.data[:id]
    assert_equal 'adamcooke', result.data[:username]
  end

  def test_setting_statuses_and_headers
    @action = @controller.actions[:info]
    assert result = @action.execute(Moonrope::ParamSet.new('user' => 'teapot'))
    assert_equal 'validation-error', result.status
  end
  
  def test_auth_is_passed_to_structures
    admin_user = User.new
    admin_user.admin = true
    action = @controller.actions[:info]

    Moonrope.globals(:auth => admin_user) do
      assert result = action.execute
      assert_equal 12345, result.data[:private_code]
    end

    Moonrope.globals(:auth => nil) do
      assert result = action.execute
      assert_equal nil, result.data[:private_code]
    end
  end
  
  def test_before_filters
    @action = @controller.actions[:info]
    assert result = @action.execute
    assert_equal "World", result.headers["X-Hello"]
  end
  
  def test_errors
    @action = @controller.actions[:info]
    assert result = @action.execute(Moonrope::ParamSet.new('user' => 'notfound'))
    assert_equal 'not-found', result.status
    assert result.data[:message]
  end
  
  def test_result_can_be_expressed_as_a_hash
    assert result = @action.execute
    assert hash = result.to_hash
    assert hash.is_a?(Hash), "result.to_hash does not return a hash"
    assert_equal 'success', hash[:status]
    assert hash[:time].is_a?(Float)
    assert hash[:flags].is_a?(Hash)
  end
  
  def test_result_can_be_expressed_as_json
    assert result = @action.execute
    assert json = result.to_json
    assert json.is_a?(String)
  end
  
end
