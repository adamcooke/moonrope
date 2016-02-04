class AuthenticatorsTest < Test::Unit::TestCase

  def test_that_by_default_actions_dont_have_an_authenticator
    base = Moonrope::Base.new do
      controller :users do
        action :list
      end
    end
    assert_equal nil, (base/:users/:list).authenticator_to_use
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

      controller :users do
        authenticator :controller_specific
        action :list
        action :show do
          authenticator :action_specific
        end
      end
    end
    assert_equal :controller_specific, (base/:users/:list).authenticator_to_use.name
    assert_equal :action_specific, (base/:users/:show).authenticator_to_use.name
  end

end
