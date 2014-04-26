class RackRequestTest < Test::Unit::TestCase

  
  def test_validation
    request = $mr.request({}, "v1/users/list")
    assert_equal true, request.valid?
    request = $mr.request({}, "v1/missing/unknown")
    assert_equal false, request.valid?
  
    request = $mr.request({}, "v1")
    assert_equal false, request.valid?
    request = $mr.request({}, "v1/users")
    assert_equal false, request.valid?
    request = $mr.request({}, "vasd/users")
    assert_equal false, request.valid?
  end
  
  def test_controllers_and_actions
    request = $mr.request({}, "v1/users/list")
    assert request.controller.is_a?(Moonrope::Controllers::Controller)
    assert_equal :users, request.controller.name
    assert request.action.is_a?(Moonrope::Controllers::Action)
    assert_equal :list, request.action.name
  end
  
end
