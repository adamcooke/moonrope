class ControllersTest < Test::Unit::TestCase

  def test_controllers_are_defined
    assert_equal 1, $mr.controllers.size
    assert_equal true, $mr.controllers.all? { |s| s.is_a?(Moonrope::Controller)}
  end
  
  def test_controller_definition
    controller = $mr.controller(:users)
    assert_equal true, controller.is_a?(Moonrope::Controller)
    assert controller.actions.is_a?(Hash)
    assert_equal :users, controller.name
    assert_equal 2, controller.actions.size
  end

end
