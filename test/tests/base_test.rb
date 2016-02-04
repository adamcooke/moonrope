class ControllersTest < Test::Unit::TestCase

  def test_basic_definitions
    base = Moonrope::Base.new do
      authenticator :default do
        lookup { :person }
      end
      controller :users do
        action :list
      end
      controller :animals
      structure :user
      structure :animal
    end

    # Check they are added to the base
    assert_equal 2, base.controllers.size
    assert_equal true, base.controllers.all? { |s| s.is_a?(Moonrope::Controller)}
    assert_equal 2, base.structures.size
    assert_equal true, base.structures.all? { |s| s.is_a?(Moonrope::Structure)}
    assert_equal 1, base.authenticators.size
    assert_equal true, base.authenticators.all? { |_,v| v.is_a?(Moonrope::Authenticator) }

    # Check they can be accessed
    assert_equal :users, base.controller(:users).name
    assert_equal :animals, base.controller(:animals).name
    assert_equal :user, base.structure(:user).name
    assert_equal :animal, base.structure(:animal).name

    # Check controllers & actions can be found nicely
    assert_equal :list, (base / :users / :list).name
    assert_equal :user, (base[:user]).name
  end

end
