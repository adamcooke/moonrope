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
    assert result.is_a?(Hash), "result is not a hash"
    assert result[:pagination], "result[:pagination] is not present"
    assert result[:records].is_a?(Array), "result[:records] is not an array"
    assert_equal 3, result[:pagination][:page], "result[:pagination][:page] is not the same as we passed in"
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
    assert result.is_a?(Hash)
    assert_equal 1, result[:id]
    assert_equal 'adamcooke', result[:username]
  end

end
