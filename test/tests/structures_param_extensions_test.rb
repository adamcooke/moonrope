class StructuresParamExtensionsTest < Test::Unit::TestCase
  def setup
    @base = Moonrope::Base.new do
      structure :animal do
        basic :id
        full :color
        expansion :user, :structure => :user
      end
      structure :user do
        basic :id
      end
      controller :users do
        action :info do
          action do
            structure @auth_user
          end
        end
      end
    end
    @user = User.new(:id => 456)
    @animal = Animal.new(:id => 123, :user => @user, :color => 'blue')
  end

  def test_no_expansions_occur_by_default_with_array
    request = FakeRequest.new(:params => {'_expansions' => ['user']})
    environment = Moonrope::EvalEnvironment.new(@base, request)
    structure = environment.structure(:animal, @animal)
    assert_equal nil, structure[:user]
  end

  def test_default_behaviour_when_paramable_is_only_option
    request = FakeRequest.new(:params => {})
    environment = Moonrope::EvalEnvironment.new(@base, request)
    # From nil
    structure = environment.structure(:animal, @animal, :paramable => true)
    assert_equal nil, structure[:user]
    assert_equal nil, structure[:color]
  end

  def test_no_expansions_occur_by_default_with_true
    request = FakeRequest.new(:params => {'_expansions' => true})
    environment = Moonrope::EvalEnvironment.new(@base, request)
    structure = environment.structure(:animal, @animal)
    assert_equal nil, structure[:user]
  end

  def test_expansions_use_paramable_value_as_default
    request = FakeRequest.new(:params => {})
    environment = Moonrope::EvalEnvironment.new(@base, request)
    # From nil
    structure = environment.structure(:animal, @animal, :paramable => {:expansions => nil})
    assert_equal nil, structure[:user]
    # From true
    structure = environment.structure(:animal, @animal, :paramable => {:expansions => true})
    assert_equal Hash, structure[:user].class
    # From a list
    structure = environment.structure(:animal, @animal, :paramable => {:expansions => [:user]})
    assert_equal Hash, structure[:user].class
  end

  def test_all_expansions_are_provided_when_paramable_is_true
    request = FakeRequest.new(:params => {"_expansions" => true})
    environment = Moonrope::EvalEnvironment.new(@base, request)
    structure = environment.structure(:animal, @animal, :paramable => true)
    assert_equal Hash, structure[:user].class
  end

  def test_using_array_as_expansions_param
    request = FakeRequest.new(:params => {'_expansions' => ['user']})
    environment = Moonrope::EvalEnvironment.new(@base, request)
    # Works
    structure = environment.structure(:animal, @animal, :paramable => {:expansions => [:user]})
    assert_equal Hash, structure[:user].class
    # Works
    structure = environment.structure(:animal, @animal, :paramable => {:expansions => true})
    assert_equal Hash, structure[:user].class
    # Shouldn't ret
    structure = environment.structure(:animal, @animal, :paramable => {:expansions => [:other]})
    assert_equal nil, structure[:user]
  end

  def test_surpressing_default_expansions_with_empty_array
    request = FakeRequest.new(:params => {'_expansions' => []})
    environment = Moonrope::EvalEnvironment.new(@base, request)
    # Shouldn't return the user structure because we've asked for none
    structure = environment.structure(:animal, @animal, :paramable => {:expansions => [:user]})
    assert_equal nil, structure[:user]
    # Shouldn't return the user structure because we've asked for none
    structure = environment.structure(:animal, @animal, :paramable => {:expansions => true})
    assert_equal nil, structure[:user]
  end

  def test_surpressing_default_expansions_with_false
    request = FakeRequest.new(:params => {'_expansions' => false})
    environment = Moonrope::EvalEnvironment.new(@base, request)
    # Shouldn't return the user structure because we've asked for none
    structure = environment.structure(:animal, @animal, :paramable => true)
    assert_equal nil, structure[:user]
    # Shouldn't return the user structure because we've asked for none
    structure = environment.structure(:animal, @animal, :paramable => {:expansions => [:user]})
    assert_equal nil, structure[:user]
    # Shouldn't return the user structure because we've asked for none
    structure = environment.structure(:animal, @animal, :paramable => {:expansions => true})
    assert_equal nil, structure[:user]
  end


  def test_using_true_as_expansions_param_to_return_all_suitable_expansions
    request = FakeRequest.new(:params => {'_expansions' => true})
    environment = Moonrope::EvalEnvironment.new(@base, request)
    # Requesting all with no default
    structure = environment.structure(:animal, @animal, :paramable => {:expansions => nil})
    assert_equal Hash, structure[:user].class
    # Requesting all with no array default
    structure = environment.structure(:animal, @animal, :paramable => {:expansions => [:user]})
    assert_equal Hash, structure[:user].class
    # Requesting all with true default
    structure = environment.structure(:animal, @animal, :paramable => {:expansions => true})
    assert_equal Hash, structure[:user].class
  end

  def test_empty_paramable_array
    request = FakeRequest.new(:params => {'_expansions' => true})
    environment = Moonrope::EvalEnvironment.new(@base, request)
    # Should not return anything because paramable doesn't specify expansions
    # as a suitable option
    structure = environment.structure(:animal, @animal, :paramable => {})
    assert_equal nil, structure[:user]
  end

  def test_returning_full_data_by_default
    request = FakeRequest.new()
    environment = Moonrope::EvalEnvironment.new(@base, request)
    structure = environment.structure(:animal, @animal, :paramable => {:full => true, :expansions => false})
    assert_equal String, structure[:color].class
  end

  def test_full_value_provides_full_access
    request = FakeRequest.new(:params => {'_full' => true})
    environment = Moonrope::EvalEnvironment.new(@base, request)
    # No full value set
    structure = environment.structure(:animal, @animal, :paramable => {})
    assert_equal nil, structure[:color]
    # With full set as default
    structure = environment.structure(:animal, @animal, :paramable => {:full => true})
    assert_equal String, structure[:color].class
    # With full set as hidden by default
    structure = environment.structure(:animal, @animal, :paramable => {:full => false})
    assert_equal String, structure[:color].class
  end

  def test_supressing_default_full_data
    request = FakeRequest.new(:params => {'_full' => false})
    environment = Moonrope::EvalEnvironment.new(@base, request)
    structure = environment.structure(:animal, @animal, :paramable => {:full => true})
    assert_equal nil, structure[:color]
  end

end
