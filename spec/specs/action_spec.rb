require 'spec_helper'
require 'moonrope/base'
require 'moonrope/controller'
require 'moonrope/action'
require 'moonrope/param_set'
require 'moonrope/eval_environment'

describe Moonrope::Action do
  subject(:base) { Moonrope::Base.new }
  subject(:controller) { Moonrope::Controller.new(base, :users) }
  subject(:action) { Moonrope::Action.new(controller, :list) }
  subject(:request) { FakeRequest.new }
  subject(:env) { Moonrope::EvalEnvironment.new(base, request, action) }

  context "an action" do
    it "should be able to have a name" do
      expect(action.name).to eq :list
    end

    it "should be able to have a description" do
      action.dsl.description "Some description"
      expect(action.description).to eq("Some description")
    end

    it "should have a hash of params" do
      action.dsl.param :username
      action.dsl.param :password
      expect(action.params).to be_a(Hash)
      expect(action.params.size).to eq(2)
    end

    it "should have a return value" do
      action.dsl.returns :hash
      expect(action.returns).to be_a(Hash)
    end

    it "should have errors" do
      action.dsl.error 'SomeError', "With Description"
      expect(action.errors).to be_a(Hash)
      expect(action.errors.size).to eq 1
    end

    it "should be able to use shared actions from the controller" do
      controller.dsl.shared_action :crud do
        param :username
      end
      action.dsl.use :crud
      expect(action.params.size).to eq 1
    end

    it "shuold raise an error if tries to use a share that doesn't exist" do
      expect { action.dsl.use :crud }.to raise_error(Moonrope::Errors::InvalidSharedAction)
    end

    it "should be able to use shared actions from the base" do
      base.dsl.shared_action :some_base_thing do
        param :username
      end
      action.dsl.use :some_base_thing
      expect(action.params.size).to eq 1
    end

    it "should have a action blocks" do
      action.dsl.action { true }
      expect(action.actions).to be_a(Array)
      expect(action.actions.first).to be_a(Proc)
    end
  end

  context "#default_params" do
    it "should return the default params for the action" do
      action.dsl.param :param_with_default, :default => 100
      action.dsl.param :param_with_no_default
      expect(action.default_params).to be_a Hash
      expect(action.default_params.size).to eq 1
      expect(action.default_params['param_with_default']).to eq 100
    end
  end

  context "#validate_parameters" do
    it "should return an error if a required parameter is missing" do
      action = Moonrope::Action.new(controller, :list) do
        param :param, :required => true
      end
      param_set = Moonrope::ParamSet.new
      expect { action.validate_parameters(param_set) }.to raise_error(Moonrope::Errors::ParameterError)
    end

    it "should return an error if a parameter doesn't match its regex" do
      action = Moonrope::Action.new(controller, :list) do
        param :param, :regex => /\Ahello\z/
      end
      param_set = Moonrope::ParamSet.new('param' => 'nope')
      expect { action.validate_parameters(param_set) }.to raise_error(Moonrope::Errors::ParameterError)
      param_set = Moonrope::ParamSet.new('param' => 'hello')
      expect { action.validate_parameters(param_set) }.to_not raise_error
    end

    it "should return an error if a parameter isn't included in an options list" do
      action = Moonrope::Action.new(controller, :list) do
        param :param, :options => ['apple', 'orange']
      end
      param_set = Moonrope::ParamSet.new('param' => 'banana')
      expect { action.validate_parameters(param_set) }.to raise_error(Moonrope::Errors::ParameterError)
      param_set = Moonrope::ParamSet.new('param' => 'apple')
      expect { action.validate_parameters(param_set) }.to_not raise_error
    end

    it "should return an error if the type is invalid" do
      action = Moonrope::Action.new(controller, :list) do
        param :param, :type => String
      end
      param_set = Moonrope::ParamSet.new('param' => 123)
      expect { action.validate_parameters(param_set) }.to raise_error(Moonrope::Errors::ParameterError)
      param_set = Moonrope::ParamSet.new('param' => 'apple')
      expect { action.validate_parameters(param_set) }.to_not raise_error
    end

    it "should return an error if the type is a boolean and it is invalid" do
      action = Moonrope::Action.new(controller, :list) do
        param :param, :type => :boolean
      end
      param_set = Moonrope::ParamSet.new('param' => 123)
      expect { action.validate_parameters(param_set) }.to raise_error(Moonrope::Errors::ParameterError)
      param_set = Moonrope::ParamSet.new('param' => 'true')
      expect { action.validate_parameters(param_set) }.to_not raise_error
      param_set = Moonrope::ParamSet.new('param' => 1)
      expect { action.validate_parameters(param_set) }.to_not raise_error
      param_set = Moonrope::ParamSet.new('param' => false)
      expect { action.validate_parameters(param_set) }.to_not raise_error
    end

    it "should not return an error if the type is a symbol" do
      action = Moonrope::Action.new(controller, :list) do
        param :param, :type => :something
      end
      param_set = Moonrope::ParamSet.new('param' => 'anything')
      expect { action.validate_parameters(param_set) }.to_not raise_error
      param_set = Moonrope::ParamSet.new('param' => 1234.3)
      expect { action.validate_parameters(param_set) }.to_not raise_error
    end
  end

  context "#access_rule_to_use" do
    it "should return the action's access rule if defined on action" do
      action.dsl.access_rule :rule
      expect(action.access_rule_to_use).to eq(:rule)
    end

    it "should return the controller's access rule if none on action" do
      controller.access_rule = :crule
      expect(action.access_rule_to_use).to eq(:crule)
    end

    it "should return the default access rule if none on action or controller" do
      expect(action.access_rule_to_use).to eq(:default)
    end
  end

  context "#authenticator_to_use" do
    it "should return the action's authentication if defined on action" do
      base.dsl.authenticator :something
      action.dsl.authenticator :something
      expect(action.authenticator_to_use).to be_a(Moonrope::Authenticator)
      expect(action.authenticator_to_use.name).to eq(:something)
    end

    it "should return the controller's authenticator if none on action" do
      base.dsl.authenticator :csomething
      controller.dsl.authenticator :csomething
      expect(action.authenticator_to_use).to be_a(Moonrope::Authenticator)
      expect(action.authenticator_to_use.name).to eq(:csomething)
    end

    it "should return no authenticator if none on action or controller and none are defined" do
      expect(action.authenticator_to_use).to eq :none
    end

    it "should return default authenticator if none on action or controller and there is a default" do
      base.dsl.authenticator :default
      expect(action.authenticator_to_use).to be_a(Moonrope::Authenticator)
      expect(action.authenticator_to_use.name).to eq(:default)
    end

    it "should return not_found if the chosen authenticator isn't valid" do
      action.dsl.authenticator :something
      expect(action.authenticator_to_use).to eq :not_found
    end
  end

  context "#convert_errors_to_action_result" do
    it "should return the block result if no errors" do
      result = action.convert_errors_to_action_result { 1234 }
      expect(result).to eq(1234)
    end

    it "should return an ActionResult if a request error is encountered" do
      result = action.convert_errors_to_action_result do
        raise Moonrope::Errors::ParameterError, "Invalid param"
      end
      expect(result).to be_a(Moonrope::ActionResult)
    end

    it "should return an ActionResult if a registered external error is encountered" do
      class SomeError < StandardError
      end
      base.register_external_error SomeError do |exception, result|
        result.status = 'some-error'
        result.data = {:hello => "world"}
      end
      result = action.convert_errors_to_action_result do
        raise SomeError
      end
      expect(result).to be_a(Moonrope::ActionResult)
      expect(result.status).to eq('some-error')
      expect(result.data).to be_a(Hash)
      expect(result.data[:hello]).to eq 'world'
    end

    it "should raise as normal for any non recognized error" do
      expect { action.convert_errors_to_action_result{ raise StandardError }}.to raise_error(StandardError)
    end
  end

  context "#check_access" do
    it "should return true if no authenticator is available" do
      expect(action.check_access(env)).to be true
    end

    it "should return an error if the given access rule is not defined on the authenticator" do
      base.dsl.authenticator :default
      action.dsl.access_rule :invalid_rule
      expect { action.check_access(env) }.to raise_error(Moonrope::Errors::MissingAccessRule)
    end

    it "should return true if the authenticator has no default rule and the default has been requested" do
      base.dsl.authenticator :default
      expect(action.access_rule_to_use).to eq :default
      expect(action.check_access(env)).to be true
    end

    it "should return the value of the authenticators access block" do
      rule_has_executed = false
      base.dsl.authenticator :default do
        rule :default, "NotPermitted" do
          rule_has_executed = true
          false
        end
      end
      expect(action.check_access(env)).to eq false
      expect(rule_has_executed).to be true
    end
  end

  context "#execute" do

    it "should validate parameters are valid" do
      allow(action).to receive(:validate_parameters).and_return true
      action.dsl.action { true }
      action.execute(env)
      expect(action).to have_received(:validate_parameters).once
    end

    it "should execute before actions from the controller" do
      before_action_run = false
      controller.dsl.before { before_action_run = true }
      action.dsl.action { true }
      action.execute(env)
      expect(before_action_run).to be true
    end

    it "should return an ActionResult instance" do
      action.dsl.action { true }
      result = action.execute(env)
      expect(result).to be_a Moonrope::ActionResult
    end

    it "should have a status" do
      action.dsl.action { true }
      expect(action.execute(env).status).to eq 'success'
    end

    it "should return a time" do
      action.dsl.action { true }
      expect(action.execute(env).time).to be_a(Float)
    end

    it "should return the result" do
      action.dsl.action { 1234 }
      expect(action.execute(env).data).to eq 1234
    end

    it "should include flags from the eval environment" do
      action.dsl.action do
        set_flag 'hello', 'world'
      end
      result = action.execute(env)
      expect(result.flags).to be_a(Hash)
      expect(result.flags['hello']).to eq 'world'
    end

    it "should include headers from the eval environment" do
      action.dsl.action do
        set_header 'X-Something', 'Monkey'
      end
      result = action.execute(env)
      expect(result.headers).to be_a(Hash)
      expect(result.headers['X-Something']).to eq 'Monkey'
    end
  end

  context "#can_change_full?" do
    it "should return true if the action is fully paramable" do
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:paramable => true}
      expect(action.can_change_full?).to be true
    end

    it "should return true if the action paramable allow full changes" do
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:paramable => {:full => true}}
      expect(action.can_change_full?).to be true
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:paramable => {:full => false}}
      expect(action.can_change_full?).to be true
    end

    it "should return false otherwise" do
      action.dsl.returns :hash, :structure => :user, :structure_opts => {}
      expect(action.can_change_full?).to be false
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:full => true}
      expect(action.can_change_full?).to be false
    end
  end

  context "#includes_full_attributes?" do
    it "should return true if the action is paramable" do
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:paramable => {:full => true}}
      expect(action.includes_full_attributes?).to be true
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:paramable => {:full => false}}
      expect(action.includes_full_attributes?).to be false
    end

    it "should return true if it always returns full attributes" do
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:full => true}
      expect(action.includes_full_attributes?).to be true
    end

    it "should be false if paramable is enabled" do
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:paramable => true}
      expect(action.includes_full_attributes?).to be false
    end

    it "should return false otherwise" do
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:full => false}
      expect(action.includes_full_attributes?).to be false
      action.dsl.returns :hash, :structure => :user, :structure_opts => {}
      expect(action.includes_full_attributes?).to be false
    end
  end

  context "#can_change_expansions?" do
    it "should return true if the action is fully paramable" do
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:paramable => true}
      expect(action.can_change_expansions?).to be true
    end
    it "should return true if the action paramable allow expansion changes" do
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:paramable => {:expansions => true}}
      expect(action.can_change_expansions?).to be true
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:paramable => {:expansions => false}}
      expect(action.can_change_expansions?).to be true
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:paramable => {:expansions => []}}
      expect(action.can_change_expansions?).to be true
    end

    it "should return false otherwise" do
      action.dsl.returns :hash, :structure => :user, :structure_opts => {}
      expect(action.can_change_expansions?).to be false
    end
  end

  context "#includes_expansion?" do
    it "should return false if the action's paramable expansions are true" do
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:paramable => true}
      expect(action.includes_expansion?(:user)).to be false
    end

    it "should return true if the action always returns all expansions" do
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:expansions => true}
      expect(action.includes_expansion?(:user)).to be true
    end

    it "should return true if the action's paramable expansions is an array and it includes the expansion" do
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:paramable => {:expansions => [:user]}}
      expect(action.includes_expansion?(:user)).to be true
      expect(action.includes_expansion?(:another)).to be false
    end

    it "should return true if the action expansions is an array and it includes the expansion" do
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:expansions => [:user]}
      expect(action.includes_expansion?(:user)).to be true
      expect(action.includes_expansion?(:another)).to be false
    end

    it "should return false otherwise" do
      action.dsl.returns :hash, :structure => :user
      expect(action.includes_expansion?(:user)).to be false
    end
  end

  context "#available_expansions" do
    it "should include all the structure's expansions if no array if expansions is provided" do
      base.dsl.structure :user do
        expansion :owner
        expansion :admin
      end
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:paramable => true}
      expect(action.available_expansions).to eq([:owner, :admin])
    end

    it "should include only listed expansions if an array is set" do
      action.dsl.returns :hash, :structure => :user, :structure_opts => {:paramable => {:expansions => [:owner]}}
      expect(action.available_expansions).to eq([:owner])
    end

    it "should be empty if there's no structure" do
      action.dsl.returns :hash
      expect(action.available_expansions).to eq([])
    end
  end

  context "dsl#filterable" do
    before do
      action.dsl.filterable do
        attribute :name
        attribute :user_id, :operators => [:eq, :not_eq, :in, :not_in] do |operator, value, scope|
          scope.where(:user => User.find_by_id(value) || error('InvalidUser'))
        end
      end
    end

    it "should have an hash of fields" do
      expect(action.filters).to be_a(Hash)
      expect(action.filters[:name]).to be_a(Hash)
      expect(action.filters[:user_id]).to be_a(Hash)
      expect(action.filters[:user_id][:block]).to be_a(Proc)
    end

    it "should add a 'filters' param" do
      expect(action.params[:filters]).to be_a Hash
    end

    it "should add an error for filter errors" do
      expect(action.errors['FilterError']).to be_a Hash
    end

  end
end
