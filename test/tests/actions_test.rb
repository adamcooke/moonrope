class ActionsTest < Test::Unit::TestCase

  def test_basic_definition
    action = $mr.controller(:users) / :list
    assert action.is_a?(Moonrope::Controllers::Action)
    assert_equal :list, action.name
    assert action.description
    assert action.description.length > 0
  end
  
  def test_params
    action = $mr.controller(:users) / :list
    assert action.params.is_a?(Hash), "Action#params is not an hash"
  end
  
  def test_access
    action = $mr.controller(:users) / :list
    assert action.access.is_a?(Proc)
  end
  
  def test_action
    action = $mr.controller(:users) / :list
    assert action.action.is_a?(Proc)
  end
  
  def test_calling_actions
    action = $mr.controller(:users) / :list
    assert result = action.execute
    assert result.is_a?(Moonrope::Controllers::ActionResult), "result is not a ActionResult"
    assert result.data.is_a?(Array), "result.data is not an array"
    assert result.flags.is_a?(Hash), "result.flags is not a hash"
    assert result.flags[:pagination], "result.flags[:pagination] is not a hash"
    assert_equal 'success', result.status
    assert result.headers.is_a?(Hash)
  end
  
  def test_checking_access
    action = $mr.controller(:users) / :list
    # unauthenticated
    assert_equal false, action.check_access
    # authenticated
    authenticated_request = FakeRequest.new(:authenticated_user => User.new)
    assert_equal true, action.check_access(authenticated_request)
  end
  
  def test_check_structures
    action = $mr.controller(:users) / :info
    assert result = action.execute
    assert result.is_a?(Moonrope::Controllers::ActionResult), "result is not a ActionResult"
    assert_equal 1, result.data[:id]
    assert_equal 'adamcooke', result.data[:username]
  end
  
  def test_request_is_passed_to_structures
    action = $mr.controller(:users) / :info
    # authenticated
    admin_user = User.new
    admin_user.admin = true
    authenticated_request = FakeRequest.new(:authenticated_user => admin_user)
    assert result = action.execute(authenticated_request)
    assert_equal 12345, result.data[:private_code]
    # unauthenticated
    assert result = action.execute
    assert_equal nil, result.data[:private_code]
  end
  
  def test_before_filters
    action = $mr.controller(:users) / :info
    assert result = action.execute
    assert_equal "World", result.headers["X-Hello"]
  end
  
  def test_result_can_be_expressed_as_a_hash
    action = $mr.controller(:users) / :list
    assert result = action.execute
    assert hash = result.to_hash
    assert hash.is_a?(Hash), "result.to_hash does not return a hash"
    assert_equal 'success', hash[:status]
    assert hash[:time].is_a?(Float)
    assert hash[:flags].is_a?(Hash)
  end
  
  def test_result_can_be_expressed_as_json
    action = $mr.controller(:users) / :list
    assert result = action.execute
    assert json = result.to_json
    assert json.is_a?(String)
  end
  
end
