require 'spec_helper'
require 'moonrope/param_set'

describe Moonrope::ParamSet do

  context "a param set" do
    subject(:param_set) { Moonrope::ParamSet.new('example' => 'Hello') }

    it "should return values in hash format" do
      expect(param_set[:example]).to eq('Hello')
      expect(param_set['example']).to eq('Hello')
    end

    it "should return values in dot format" do
      expect(param_set.example).to eq('Hello')
    end

    it "should be able to say if a param exists or not" do
      expect(param_set.has?(:example)).to be true
      expect(param_set.has?('example')).to be true
      expect(param_set.has?(:unknown)).to be false
    end

    it "should return a default if one exists and there's no other value" do
      param_set._defaults = {'fruit' =>'Apple'}
      expect(param_set.has?(:fruit)).to be true
      expect(param_set.fruit).to eq 'Apple'
    end
  end

end
