class ActionAccessTest < Test::Unit::TestCase

  def setup
    @base = Moonrope::Base.new do
      authenticator :default do
        rule :default, "AccessDenied" do
          identity == :admin
        end

        rule :anonymous, "MustBeAnonymous" do
          identity.nil?
        end
      end
    end
    @controller = Moonrope::Controller.new(@base, :users)
  end

  def test_action_uses_default_access_rule_by_default
    action = Moonrope::Action.new(@controller, :list)
    # no authentication has been provided
    assert_equal false, action.check_access
    # authentication which is not correct
    authenticated_request = FakeRequest.new(:identity => :dave)
    assert_equal false, action.check_access(authenticated_request)
    # authentication which is correct
    authenticated_request = FakeRequest.new(:identity => :admin)
    assert_equal true, action.check_access(authenticated_request)
  end

  def test_action_can_use_controller_rule
    controller = Moonrope::Controller.new(@base, :users) do
      access_rule :anonymous
    end
    action = Moonrope::Action.new(controller, :list)
    # anonymous is ok
    assert_equal true, action.check_access
    # with a user is not
    authenticated_request = FakeRequest.new(:identity => :dave)
    assert_equal false, action.check_access(authenticated_request)
  end

  def test_action_can_use_action_rule
    action = Moonrope::Action.new(@controller, :list) do
      access_rule :anonymous
    end
    # anonymous is ok
    assert_equal true, action.check_access
    # with a user is not
    authenticated_request = FakeRequest.new(:identity => :dave)
    assert_equal false, action.check_access(authenticated_request)
  end

  def test_that_invalid_rule_names_raise_errors
    action = Moonrope::Action.new(@controller, :list) do
      access_rule :missing
    end
    # anonymous is ok
    assert_raises Moonrope::Errors::MissingAccessRule do
      action.check_access
    end
  end

end
