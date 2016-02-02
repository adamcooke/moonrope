class ExamplesTest < Test::Unit::TestCase

  def setup
    @base = Moonrope::Base.load(File.expand_path('../../../example', __FILE__))
  end

  def test_examples_are_valid
    assert_equal 2, @base.controllers.size
  end

end
