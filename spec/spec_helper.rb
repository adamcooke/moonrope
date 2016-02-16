$:.unshift(File.expand_path(File.join('..', 'lib')))

RSpec.configure do |config|
  config.color = true
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
end

class FakeRequest

  def initialize(options = {})
    @options = options
  end

  def params
    @params ||= Moonrope::ParamSet.new(@options[:params] || {})
  end

  def version
    @options[:version]
  end

  def identity
    @options[:identity]
  end

  def action
    nil
  end

end
