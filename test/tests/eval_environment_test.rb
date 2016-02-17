class EvalEnvironmentTest < Test::Unit::TestCase

  def setup
    @auth_user = User.new(:name => 'Admin User')
    @request = FakeRequest.new(:params => {'page' => '1'}, :version => 2, :identity => @auth_user)
    @environment = Moonrope::EvalEnvironment.new(Moonrope::Base.new, @request, nil, :accessor1 => 'Hello')
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

  def test_identity_access
    assert_equal @auth_user, @environment.identity
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

  def test_structure_access_with_auto_determination
    user_structure = @environment.base.dsl.structure(:user) do
      basic { {:id => o.id} }
    end
    structure = @environment.structure(UserWithUnderscore.new)
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

  def test_copy_attributes_from_param_set_to_an_object
    base = Moonrope::Base.new
    controller = Moonrope::Controller.new(base, :users) do
      action :save do
        param :username do |object, value|
          object.username = "#{value}!"
        end
        param :id
      end
    end

    request = FakeRequest.new(:params => {'id' => 123, 'username' => 'adam'})
    env = Moonrope::EvalEnvironment.new(base, request, controller/:save)
    user = User.new
    env.copy_params_to user, :username, :id
    assert_equal user.id, 123
    assert_equal user.username, "adam!"
  end

  def test_copy_attributes_from_share
    base = Moonrope::Base.new
    controller = Moonrope::Controller.new(base, :users) do
      shared_action :crud do
        param :username
        param :id
      end
      action :save do
        use :crud
      end
    end

    request = FakeRequest.new(:params => {'id' => 123, 'username' => 'adam'})
    env = Moonrope::EvalEnvironment.new(base, request, controller/:save)
    user = User.new
    env.copy_params_to user, :from => :crud
    assert_equal user.id, 123
    assert_equal user.username, "adam"
  end

  def test_copy_attribute_from_shared_action_within_shared_action
    base = Moonrope::Base.new
    controller = Moonrope::Controller.new(base, :users) do
      shared_action :private_code do
        param :private_code
      end
      shared_action :crud do
        param :username
        param :id
        use :private_code
      end
      action :save do
        use :crud
      end
    end

    request = FakeRequest.new(:params => {'id' => 123, 'username' => 'adam', 'private_code' => 'llama'})
    env = Moonrope::EvalEnvironment.new(base, request, controller/:save)
    user = User.new
    env.copy_params_to user, :from => :crud
    assert_equal user.username, "adam"
    assert_equal user.private_code, "llama"
  end

end

