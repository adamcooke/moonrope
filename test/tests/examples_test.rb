class ExamplesTest < Test::Unit::TestCase
  
  def setup
    @base = Moonrope::Base.load(File.expand_path('../../../examples', __FILE__))
  end
  
  def test_controllers_are_defined
    assert_equal 1, @base.controllers.size
    assert_equal true, @base.controllers.all? { |c| c.is_a?(Moonrope::Controller) }
    assert_equal :users, @base.controller(:users).name
    assert_equal 2, @base.controller(:users).befores.size
    assert_equal :list, (@base.controller(:users) / :list).name
    assert_equal :users, (@base.controller(:users) / :list).controller.name
  end
  
  def test_structures_are_defined
    assert_equal 2, @base.structures.size
    assert_equal true, @base.structures.all? { |c| c.is_a?(Moonrope::Structure) }
    assert_equal :user, @base.structure(:user).name
    assert_equal :animal, @base.structure(:animal).name
  end
  
  def test_users_list_action_responds_correctly
    action = @base.controller(:users) / :list
    assert_equal true, action.is_a?(Moonrope::Action)

    # Execute the request
    assert result = action.execute(FakeRequest.new)
    # Check that the response was what we expected
    assert_equal true, result.is_a?(Moonrope::ActionResult)
    assert_equal 'success', result.status
    assert_equal true, result.flags[:pagination].is_a?(Hash)
    assert_equal 'Monkeys', result.headers['X-Example-Header']
    assert_equal true, result.data.is_a?(Array)
    assert_equal 30, result.data.size
  end
  
end