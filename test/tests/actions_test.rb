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
    params = {'page' => 3}
    assert result = @action.execute(params)
    assert result.is_a?(Moonrope::Controllers::ActionResult), "result is not a ActionResult"
    assert result.body[:pagination], "result[:pagination] is not present"
    assert result.body[:records].is_a?(Array), "result[:records] is not an array"
    assert_equal 3, result.body[:pagination][:page], "result[:pagination][:page] is not the same as we passed in"
    # check defaults
    assert_equal 200, result.status
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
    assert_equal 1, result.body[:id]
    assert_equal 'adamcooke', result.body[:username]
  end

  def test_setting_statuses_and_headers
    @action = @controller.actions[:info]
    assert result = @action.execute('user' => 'teapot')
    assert_equal 418, result.status
    assert_equal "World", result.headers["X-Hello"]
  end

end
