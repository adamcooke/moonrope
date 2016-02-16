require 'spec_helper'
require 'moonrope/base'

describe Moonrope::Base do
  subject(:base) { Moonrope::Base.new }

  context "the base" do
    it "should be able to define & return a controller" do
      base.dsl.controller :users
      expect(base.controller(:users)).to be_a(Moonrope::Controller)
    end

    it "should be able to define & return a structure" do
      base.dsl.structure :user
      expect(base.structure(:user)).to be_a(Moonrope::Structure)
    end

    it "should be able to define & return an authenticator" do
      base.dsl.authenticator :admin
      expect(base.authenticators[:admin]).to be_a(Moonrope::Authenticator)
    end

    it "should be able to define & return an authenticator" do
      base.dsl.shared_action(:find_something) { 1234 }
      expect(base.shared_actions[:find_something]).to be_a(Proc)
    end

  end
end
