require 'spec_helper'
require 'moonrope/controller'
require 'moonrope/base'

describe Moonrope::Controller do
  context "a controller" do
    it "should be able to define & return an action" do
      controller = Moonrope::Controller.new(Moonrope::Base.new, :users) do
        action :list
      end
      expect(controller.action(:list)).to be_a(Moonrope::Action)
    end

    it "should be able to define & return a before filter" do
      controller = Moonrope::Controller.new(Moonrope::Base.new, :users) do
        before {}
      end
      expect(controller.befores.size).to eq(1)
      expect(controller.befores.first).to be_a(Moonrope::BeforeAction)
    end

    it "should be able to define & return a share block" do
      controller = Moonrope::Controller.new(Moonrope::Base.new, :users) do
        share :example do
        end
      end
      expect(controller.shares.size).to eq(1)
      expect(controller.shares[:example]).to be_a(Proc)
    end
  end
end
