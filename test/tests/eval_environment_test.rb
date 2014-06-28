class EvalEnvironmentTest < Test::Unit::TestCase
  
  def setup
    @auth_user = User.new(:name => 'Admin User')
    @request = FakeRequest.new(:params => {'page' => '1'}, :version => 2, :authenticated_user => @auth_user)
    @environment = Moonrope::EvalEnvironment.new(Moonrope::Base.new, @request, :accessor1 => 'Hello')
  end
  
  def test_version
    assert_equal 2, @environment.version
  end
  
  def test_params
    assert @environment.params.is_a?(Moonrope::ParamSet)
    assert_equal '1', @environment.params.page
  end
  
  def test_accessors
    assert_equal 'Hello', @environment.accessor1
  end
  
  def test_authenticated_user_access
    assert_equal @auth_user, @environment.auth
  end
  
  def test_setting_headers
    @environment.set_header 'Header1', 'A'
    assert_equal 'A', @environment.headers['Header1']
    @environment.set_header 'Header2', 'B'
    assert_equal 'B', @environment.headers['Header2']
  end
  
  def test_setting_flags
    @environment.set_flag 'Flag1', 'A'
    assert_equal 'A', @environment.flags['Flag1']
    @environment.set_flag 'Flag2', 'B'
    assert_equal 'B', @environment.flags['Flag2']
  end
  
  def test_structure_access
    user_structure = Moonrope::Structure.new(@environment.base, :user) do
      basic { {:id => o.id} }
    end
    structure = @environment.structure(user_structure, User.new)
    assert structure.is_a?(Hash), "structure was not a Hash, was a #{structure.class}"
  end
  
  def test_structure_for
    user_structure = @environment.base.dsl.structure(:user) do
      basic { {:id => o.id} }
    end
    structure = @environment.structure_for(:user)
    assert_equal structure, user_structure
  end
  
  def test_has_structure_for
    user_structure = @environment.base.dsl.structure(:user) do
      basic { {:id => o.id} }
    end
    assert_equal false, @environment.has_structure_for?(:blah)
    assert_equal true, @environment.has_structure_for?(:user)
  end
  
end

