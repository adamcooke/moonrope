class ActionsTest < Test::Unit::TestCase

  def setup
    @base = Moonrope::Base.new
    @controller = Moonrope::Controller.new(@base, :users)
  end

  def test_basic_definition
    action = Moonrope::Action.new(@controller, :list) do
      description "An example action with a description"
    end
    assert action.is_a?(Moonrope::Action)
    assert_equal :list, action.name
    assert action.description.is_a?(String)
    assert action.description.length > 0
  end

  def test_defining_params
    action = Moonrope::Action.new(@controller, :list) do
      param :page
      param :limit
    end
    assert action.params.is_a?(Hash)
    assert_equal [:page, :limit], action.params.keys
    assert action.params.values.all? { |p| p.is_a?(Hash) }
  end

  def test_using_shares
    controller = Moonrope::Controller.new(@base, :users) do
      shared_action :user_properties do
        error 'InvalidUsername', "Some description"
        param :username, "Blah"
        param :first_name
      end

      action :create do
        use :user_properties
        param :last_name
      end
    end

    action = controller / :create
    assert_equal(Hash, action.params.class)
    assert_equal(Hash, action.params[:username].class)
    assert_equal("Blah", action.params[:username][:description])
    assert_equal(Hash, action.errors['InvalidUsername'].class)
  end

  def test_action
    action = Moonrope::Action.new(@controller, :list) do
      action { true }
    end
    assert action.actions.is_a?(Array)
    assert action.actions.first.is_a?(Proc)
    assert_equal true, action.actions.first.call
  end

  def test_calling_actions
    action = Moonrope::Action.new(@controller, :list) do
      action { [1,2,3,4] }
    end
    assert result = action.execute
    assert result.is_a?(Moonrope::ActionResult)
    assert_equal 'success', result.status
    assert_equal [1,2,3,4], result.data
    assert_equal Float, result.time.class
    assert_equal({}, result.flags)
    assert_equal({}, result.headers)
  end

  def test_structure_method_can_be_called
    # Create a new structure to test with
    user_structure = Moonrope::Structure.new(@base, :user) do
      basic { {:id => o.id, :username => o.username}}
    end

    # Create an action which uses this structure
    action = Moonrope::Action.new(@controller, :list) do
      action do
        user = User.new(:id => 1, :username => 'adamcooke')
        structure user_structure, user
      end
    end

    # Test the structure was returned
    assert result = action.execute
    assert result.is_a?(Moonrope::ActionResult), "result is not a ActionResult"
    assert_equal 1, result.data[:id]
    assert_equal 'adamcooke', result.data[:username]
  end

  def test_structure_methods_can_be_called_with_opts_from_dsl
    # Create a new structure to test with
    user_structure = Moonrope::Structure.new(@base, :user) do
      basic :id
      full :username
    end

    # Create an action which uses this structure
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :user, :structure_opts => {:full => true}
      action do
        user = User.new(:id => 1, :username => 'adamcooke')
        structure user_structure, user, :return => true
      end
    end

    # Test the structure was returned
    assert result = action.execute
    assert_equal 1, result.data[:id]
    assert_equal 'adamcooke', result.data[:username]
  end

  def test_default_params
    action = Moonrope::Action.new(@controller, :default_params_test) do
      param :page, :default => 1234
      param :limit
      action { {:page => params.page, :limit => params.limit} }
    end
    result = action.execute
    assert_equal({'page' => 1234}, action.default_params)
    assert_equal 1234, result.data[:page]
    assert_equal nil, result.data[:limit]
  end

  def test_before_filters_are_executed
    controller = Moonrope::Controller.new(@base, :users) do
      before { set_flag :before_all, true }
      before(:other) { set_flag :before_other, true }
      before(:list) { set_flag :before_list, true }
      before(:list, :potato) { set_flag :before_list_and_potato, true }
    end

    action = Moonrope::Action.new(controller, :list) do
      action { true }
    end

    assert result = action.execute
    assert_equal true, result.flags[:before_all]
    assert_equal true, result.flags[:before_list]
    assert_equal true, result.flags[:before_list_and_potato]
    assert_equal nil, result.flags[:before_other]
  end

  def test_result_can_be_expressed_as_a_hash
    action = Moonrope::Action.new(@controller, :list) do
      action { [1,2,3] }
    end
    assert result = action.execute
    assert hash = result.to_hash
    assert hash.is_a?(Hash), "result.to_hash does not return a hash"
    assert_equal 'success', hash[:status]
    assert hash[:time].is_a?(Float)
    assert hash[:flags].is_a?(Hash)
  end

  def test_result_can_be_expressed_as_json
    action = Moonrope::Action.new(@controller, :list) do
      action { [1,2,3] }
    end
    assert result = action.execute
    assert json = result.to_json
    assert json.is_a?(String)
  end

  def test_that_param_validation_happens_on_executin
    action = Moonrope::Action.new(@controller, :list) do
      param :page, "Page number", :required => true
      action { [1,2,3] }
    end
    assert result = action.execute
    assert_equal 'parameter-error', result.status
  end

  def test_actions_params_can_be_validated_for_presence
    action = Moonrope::Action.new(@controller, :list) do
      param :page, "Page number", :required => true
    end

    # request without the param
    assert_raises Moonrope::Errors::ParameterError do
      action.validate_parameters(Moonrope::ParamSet.new)
    end

    # request with the param
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new('page' => 1))
  end

  def test_actions_params_can_be_validated_for_type
    action = Moonrope::Action.new(@controller, :list) do
      param :page, "Page number", :type => Integer
    end

    # request with a string valuee
    assert_raises Moonrope::Errors::ParameterError do
      action.validate_parameters(Moonrope::ParamSet.new('page' => 'stringy'))
    end

    # request with an integer value
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new('page' => 1))

    # request with an nil value
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new('page' => nil))
  end

  def test_actions_params_can_be_validated_for_boolean_types
    action = Moonrope::Action.new(@controller, :list) do
      param :hungry, "Are you hungry", :type => :boolean
    end

    # request with a string valuee
    assert_raises Moonrope::Errors::ParameterError do
      action.validate_parameters(Moonrope::ParamSet.new('hungry' => 'randomstring'))
    end

    assert_raises Moonrope::Errors::ParameterError do
      action.validate_parameters(Moonrope::ParamSet.new('hungry' => 2))
    end

    assert_raises Moonrope::Errors::ParameterError do
      action.validate_parameters(Moonrope::ParamSet.new('hungry' => 123))
    end

    # request with an boolean value
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new('hungry' => true))
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new('hungry' => false))

    # request with string values
    set = Moonrope::ParamSet.new('hungry' => 'true')
    assert_equal true, action.validate_parameters(set)
    assert_equal true, set.hungry

    set = Moonrope::ParamSet.new('hungry' => 'false')
    assert_equal true, action.validate_parameters(set)
    assert_equal false, set.hungry

    # request with an numeric values
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new('hungry' => 1))
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new('hungry' => 0))

    # request with nil vlaues
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new('hungry' => nil))
  end

  def test_actions_params_can_have_symbols_as_types_which_do_nothing
    action = Moonrope::Action.new(@controller, :list) do
      param :created_at, "Timestamp", :type => :timestamp
    end
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new('created_at' => 'something'))
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new('created_at' => nil))
  end

  def test_actions_params_can_be_validated_for_regex_matches
    action = Moonrope::Action.new(@controller, :list) do
      param :username, "Username", :regex => /\A[a-z]+\z/
    end
    # request with a nil value
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new)

    # request with a matching value
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new('username' => 'adam'))

    # request with a string valuee
    assert_raises Moonrope::Errors::ParameterError do
      action.validate_parameters(Moonrope::ParamSet.new('username' => 'invalid-username1234'))
    end
  end

  def test_actions_params_can_be_validated_for_option_matches
    action = Moonrope::Action.new(@controller, :list) do
      param :sort_by, :options => ["name", "age"]
    end
    # request with a nil value
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new)

    # request with a matching value
    assert_equal true, action.validate_parameters(Moonrope::ParamSet.new('sort_by' => 'name'))

    # request with a string valuee
    assert_raises Moonrope::Errors::ParameterError do
      action.validate_parameters(Moonrope::ParamSet.new('sort_by' => 'somethingelse'))
    end
  end


  def test_actions_can_raise_errors
    action = Moonrope::Action.new(@controller, :list) do
      action do
        error :not_found, "Something wasn't found"
      end
    end
    assert result = action.execute
    assert_equal "not-found", result.status
    assert_equal({:message => "Something wasn't found"}, result.data)
  end

  def test_actions_can_raise_structured_errors
    action = Moonrope::Action.new(@controller, :list) do
      action do
        structured_error 'feature-disabled', "The feature you have requested is not currently available for this resource.", :number => 1000
      end
    end
    assert result = action.execute
    assert_equal "error", result.status
    assert_equal("feature-disabled", result.data[:code])
    assert_equal("The feature you have requested is not currently available for this resource.", result.data[:message])
    assert_equal(1000, result.data[:number])
  end

  def test_actions_can_raise_structured_errors_through_the_error_method
    action = Moonrope::Action.new(@controller, :list) do
      action do
        error :structured_error, 'feature-disabled', "The feature you have requested is not currently available for this resource."
      end
    end
    assert result = action.execute
    assert_equal "error", result.status
    assert_equal("feature-disabled", result.data[:code])
    assert_equal("The feature you have requested is not currently available for this resource.", result.data[:message])
  end

  def test_actions_can_raise_structured_errors_through_the_error_method_using_a_string
    action = Moonrope::Action.new(@controller, :list) do
      action do
        error 'feature-disabled', "The feature you have requested is not currently available for this resource."
      end
    end
    assert result = action.execute
    assert_equal "error", result.status
    assert_equal("feature-disabled", result.data[:code])
    assert_equal("The feature you have requested is not currently available for this resource.", result.data[:message])
  end

  def test_actions_can_raise_structured_errors_referencing_action_errors
    action = Moonrope::Action.new(@controller, :list) do
      error "NoWidgetsFound", "No widgets were found with level {widget_level}"
      action do
        error 'NoWidgetsFound', :widget_level => 42
      end
    end
    assert result = action.execute
    assert_equal "error", result.status
    assert_equal "NoWidgetsFound", result.data[:code]
    assert_equal "No widgets were found with level 42", result.data[:message]
    assert_equal 42, result.data[:widget_level]
  end

  class DummyError < StandardError; end

  def test_catching_external_errors
    @controller.base.register_external_error DummyError do |exp, res|
      res.status = 'dummy-error'
      res.data = {:message => exp.message}
    end

    action = Moonrope::Action.new(@controller, :list) do
      action do
        raise DummyError, "Something happened"
      end
    end

    assert result = action.execute
    assert_equal 'dummy-error', result.status
    assert_equal({:message => 'Something happened'}, result.data)
  end

  class DummyError2 < StandardError; end

  def test_non_defined_errors_are_raised
    action = Moonrope::Action.new(@controller, :list) do
      action do
        raise DummyError2, "Something happened"
      end
    end
    assert_raises(DummyError2) { action.execute }
  end

  def test_can_change_full_attribute
    # can't change when no ops
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal
    end
    assert_equal(false, action.can_change_full?)

    # can change when paramable is true
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal, :structure_opts => {:paramable => true}
    end
    assert_equal(true, action.can_change_full?)

    # can change when specified
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal, :structure_opts => {:paramable => {:full => true}}
    end
    assert_equal(true, action.can_change_full?)

    # can't change when not specified
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal, :structure_opts => {:paramable => {}}
    end
    assert_equal(false, action.can_change_full?)
  end

  def test_includes_full_attributes
    #not included by default
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal
    end
    assert_equal(false, action.includes_full_attributes?)

    # not included when paramable is just true
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal, :structure_opts => {:paramable => true}
    end
    assert_equal(false, action.includes_full_attributes?)

    # included when paramable sets the default to true
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal, :structure_opts => {:paramable => {:full => true}}
    end
    assert_equal(true, action.includes_full_attributes?)

    # included when it's full anyway
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal, :structure_opts => {:full => true}
    end
    assert_equal(true, action.includes_full_attributes?)
  end


  def test_can_change_expansions_attribute
    # can't change when no ops
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal
    end
    assert_equal(false, action.can_change_expansions?)

    # can change when paramable is true
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal, :structure_opts => {:paramable => true}
    end
    assert_equal(true, action.can_change_expansions?)

    # can change when specified
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal, :structure_opts => {:paramable => {:expansions => true}}
    end
    assert_equal(true, action.can_change_expansions?)

    # can't change when not specified
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal, :structure_opts => {:paramable => {}}
    end
    assert_equal(false, action.can_change_expansions?)
  end

  def test_includes_expansion
    #not included by default
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal
    end
    assert_equal(false, action.includes_expansion?(:blah))

    # not included when paramable is just true
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal, :structure_opts => {:paramable => true}
    end
    assert_equal(false, action.includes_expansion?(:blah))

    # included when paramable sets the default to true
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal, :structure_opts => {:paramable => {:expansions => true}}
    end
    assert_equal(true, action.includes_expansion?(:blah))

    # included when it's expansions anyway
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal, :structure_opts => {:expansions => true}
    end
    assert_equal(true, action.includes_expansion?(:blah))

    # included when expansions is an array
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal, :structure_opts => {:expansions => [:blah]}
    end
    assert_equal(true, action.includes_expansion?(:blah))
    assert_equal(false, action.includes_expansion?(:another))

    # included when paramable expansions is an array
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal, :structure_opts => {:paramable => {:expansions => [:blah]}}
    end
    assert_equal(true, action.includes_expansion?(:blah))
    assert_equal(false, action.includes_expansion?(:another))
  end

  def test_available_expansions_array_on_actions
    # if an array is provided, it should return the items in the array
    action = Moonrope::Action.new(@controller, :list) do
      returns :hash, :structure => :animal, :structure_opts => {:paramable => {:expansions => [:user]}}
    end
    assert_equal([:user], action.available_expansions)
  end

  def test_that_param_can_copy_data_from_structures
    base = Moonrope::Base.new do
      structure :user do
        basic :username, "The username for the user", :type => String, :eg => 123
      end

      controller :users do
        action :save do
          param :username, :from_structure => :user
        end
      end
    end

    action = base/:users/:save
    assert_equal "The username for the user", action.params[:username][:description]
    assert_equal String, action.params[:username][:type]
  end


end
