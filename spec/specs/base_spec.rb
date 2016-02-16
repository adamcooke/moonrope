require 'spec_helper'
require 'moonrope/base'

describe Moonrope::Base do
  context "the base" do
    it "should be able to define & return a controller" do
      base = Moonrope::Base.new do
        controller :users
      end
      expect(base.controller(:users)).to be_a(Moonrope::Controller)
    end

    it "should be able to define & return a structure" do
      base = Moonrope::Base.new do
        structure :user
      end
      expect(base.structure(:user)).to be_a(Moonrope::Structure)
    end

    it "should be able to define & return an authenticator" do
      base = Moonrope::Base.new do
        authenticator :admin do
        end
      end
      expect(base.authenticators[:admin]).to be_a(Moonrope::Authenticator)
    end
  end
end
