require 'ostruct'

class ParamSetTest < Test::Unit::TestCase

  def test_param_set
    set = Moonrope::ParamSet.new('fruit' => 'Banana')
    # Test that values which aren't included are nil
    assert_equal nil, set.vegetable
    assert_equal nil, set[:vegetable]
    # Test values can be accessed if they are provided
    assert_equal 'Banana', set.fruit
    assert_equal 'Banana', set[:fruit]
    assert_equal 'Banana', set['fruit']
  end

  def test_default_params
    set = Moonrope::ParamSet.new('fruit' => 'Banana')
    set._defaults = {'vegetable' => 'Tomato', 'fruit' => 'Apple'}
    # Check that the default is provided
    assert_equal 'Tomato', set.vegetable
    # Check that the fruit default isn't used.
    assert_equal 'Banana', set.fruit
  end

  def test_nilification
    set = Moonrope::ParamSet.new('fruit' => '')
    assert_equal nil, set.fruit
    assert_equal nil, set[:fruit]
    assert_equal nil, set['fruit']
  end

  def test_key_presence
    set = Moonrope::ParamSet.new('fruit' => 'Apple')
    set._defaults = {'meat' => 'Beef'}
    assert_equal true, set.has?(:fruit)
    assert_equal true, set.has?(:meat)
    assert_equal false, set.has?(:vegetable)
  end

  class ParamSetCopyTestThing
    attr_accessor :fruit, :vegetable
  end

end
