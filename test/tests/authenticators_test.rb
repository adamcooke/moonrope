class AuthenticatorsTest < Test::Unit::TestCase

  def test_that_by_default_actions_dont_have_an_authenticator
    base = Moonrope::Base.new do
      controller :users do
        action :list
      end
    end
    assert_equal :none, (base/:users/:list).authenticator_to_use
  end

  def test_actions_will_use_default_authenticator
    base = Moonrope::Base.new do
      authenticator :default do
        lookup { true }
      end
      controller :users do
        action :list
      end
    end
    assert_equal :default, (base/:users/:list).authenticator_to_use.name
  end

  def test_actions_will_use_controller_authenticator
    base = Moonrope::Base.new do
      authenticator :default
      authenticator :controller_specific
      authenticator :action_specific
      controller :animals do
        action :list
      end
      controller :users do
        authenticator :controller_specific
        action :list
        action :show do
          authenticator :action_specific
        end
      end
    end
    assert_equal :default, (base/:animals/:list).authenticator_to_use.name
    assert_equal :controller_specific, (base/:users/:list).authenticator_to_use.name
    assert_equal :action_specific, (base/:users/:show).authenticator_to_use.name
  end

  def test_that_missing_authenticators_return_not_found
    base = Moonrope::Base.new do
      authenticator :default
      controller :animals do
        authenticator :missing
        action :list
      end
    end
    assert_equal :not_found, (base/:animals/:list).authenticator_to_use
  end

  def test_authentication_can_be_defined_via_access_rule
    base = Moonrope::Base.new do
      authenticator :some_authenticator
      controller :users do
        action :list do
          access_rule :some_authenticator => :some_rule
        end
      end
    end
    assert_equal :some_authenticator, (base/:users/:list).authenticator
    assert_equal :some_rule, (base/:users/:list).access_rule
  end

  def test_that_access_rules_can_inherit
    base = Moonrope::Base.new do
      controller :animals do
        action :list
      end
      controller :users do
        access_rule :controller_specific
        action :list
        action :show do
          access_rule :action_specific
        end
      end
    end
    assert_equal :default, (base/:animals/:list).access_rule_to_use
    assert_equal :controller_specific, (base/:users/:list).access_rule_to_use
    assert_equal :action_specific, (base/:users/:show).access_rule_to_use
  end

end
