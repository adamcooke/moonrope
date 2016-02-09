class ControllersTest < Test::Unit::TestCase

  def setup
    @base = Moonrope::Base.new
  end

  def test_controllers_actions_can_be_found_easily
    controller = Moonrope::Controller.new(@base, :users) do
      action :list do
        action { true }
      end
    end
    action = controller / :list
    assert_equal :list, action.name
    assert action.is_a?(Moonrope::Action)
  end

  def test_controllers_can_have_before_filters
    controller = Moonrope::Controller.new(@base, :users) do
      before { 1 }
      before(:list) { 3 }
      action :list do
        action { true }
      end

      action :show do
        action { true }
      end
    end
    assert_equal 2, controller.befores.size
    assert_equal 2, controller.before_actions_for(:list).size
    assert_equal 1, controller.before_actions_for(:show).size
  end


  def test_defining_param_sets
    controller = Moonrope::Controller.new(@base, :users) do
      param_set :user_properties do
        param :username
        param :first_name
      end
    end

    assert_equal(Hash, controller.param_sets.class)
    assert_equal(Hash, controller.param_sets[:user_properties].class)
    assert_equal(Hash, controller.param_sets[:user_properties][:username].class)
  end

end
