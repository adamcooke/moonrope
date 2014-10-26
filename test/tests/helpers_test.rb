class HelpersTest < Test::Unit::TestCase

  def test_helper_definitions_and_selection
    base = Moonrope::Base.new do
      # A global helper
      helper :say_hello do |name|
        "Hello #{name}!"
      end

      # A controller specific helper
      controller :users do
        helper :user_helper do |name|
          "Your name is #{name}!"
        end

        action :action1 do
          action do
            say_hello('David')
          end
        end

        action :action2 do
          action do
            user_helper('Michael')
          end
        end

        action :action3 do
          action do
            animal_helper('Bob')
          end
        end
      end

      # Another controller
      controller :animals do
        helper :animal_helper do |name|
          "Animal name is #{name}"
        end
      end
    end

    assert_equal 3, base.helpers.size
    assert_equal Moonrope::Helper, base.helper(:say_hello).class

    # see if the controller-scoped helper is only available to the cobntroller
    assert_equal nil, base.helper(:user_helper)
    assert_equal nil, base.helper(:user_helper, base / :animals)
    assert_equal Moonrope::Helper, base.helper(:user_helper, base/:users).class

    # see if running the actuions will allow usage of helpers
    result = (base/:users/:action1).execute
    assert_equal "Hello David!", result.data

    result = (base/:users/:action2).execute
    assert_equal "Your name is Michael!", result.data

    assert_raises(NoMethodError) { (base/:users/:action3).execute }
  end

  def test_unloadable_helpers
    base = Moonrope::Base.new
    base.dsl.instance_eval do
      helper :unloadable_helper, :unloadable => false do
        666
      end

      helper :normal_helper do
        111
      end
    end
    # initially they'll both exist
    assert_equal Moonrope::Helper, base.helper(:unloadable_helper).class
    assert_equal Moonrope::Helper, base.helper(:normal_helper).class
    # unload the base
    base.unload
    # now only the unloadable helper remains
    assert_equal Moonrope::Helper, base.helper(:unloadable_helper).class
    assert_equal nil, base.helper(:normal_helper)
  end

  def test_ensure_helpers_cant_be_double_loaded
    base = Moonrope::Base.new do
      helper :my_helper do
        123
      end
    end

    assert_raises Moonrope::Errors::HelperAlreadyDefined do
      base.dsl.instance_eval do
        helper :my_helper do
        end
      end
    end
  end

end
