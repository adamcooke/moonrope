class StructuresParamExtensionsTest < Test::Unit::TestCase
  def setup
    @base = Moonrope::Base.new do
      structure :animal do
        basic :id
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
    @animal = Animal.new(:id => 123, :user => @user)
  end

  def test_no_expansions_occur_by_default
    request = FakeRequest.new(:params => {'_expansions' => ['user']})
    environment = Moonrope::EvalEnvironment.new(@base, request)
    structure = environment.structure(:animal, @animal)
    assert_equal nil, structure[:user]
  end

  def test_expansions_can_be_provided_in_params
    request = FakeRequest.new(:params => {'_expansions' => ['user']})
    environment = Moonrope::EvalEnvironment.new(@base, request)
    structure = environment.structure(:animal, @animal, :expansions => :from_params)
    assert_equal Hash, structure[:user].class
  end

  def test_whitelist
    request = FakeRequest.new(:params => {'_expansions' => ['user']})
    environment = Moonrope::EvalEnvironment.new(@base, request)
    structure = environment.structure(:animal, @animal, :expansions => {:from_params => [:something_else]})
    assert_equal nil, structure[:user]
  end

end
