class ParamSetTest < Test::Unit::TestCase
  
  def test_param_set
    set = Moonrope::ParamSet.new('fruit' => 'Banana')
    assert_equal 'Banana', set.fruit
    assert_equal 'Banana', set[:fruit]
    assert_equal 'Banana', set['fruit']
  end
  
end
