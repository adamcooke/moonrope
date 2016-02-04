require 'json'
require 'logger'
require 'deep_merge/core'

require 'moonrope/action'
require 'moonrope/action_result'
require 'moonrope/base'
require 'moonrope/before_action'
require 'moonrope/controller'
require 'moonrope/dsl/base_dsl'
require 'moonrope/dsl/action_dsl'
require 'moonrope/dsl/controller_dsl'
require 'moonrope/dsl/structure_dsl'
require 'moonrope/dsl/authenticator_dsl'
require 'moonrope/authenticator'
require 'moonrope/errors'
require 'moonrope/eval_helpers'
require 'moonrope/eval_environment'
require 'moonrope/helper'
require 'moonrope/param_set'
require 'moonrope/rack_middleware'
require 'moonrope/request'
require 'moonrope/structure'
require 'moonrope/structure_attribute'
require 'moonrope/version'

require 'moonrope/railtie' if defined?(Rails)

module Moonrope

  class << self
    attr_accessor :logger

    def logger
      @logger ||= Logger.new(STDOUT)
    end
  end

end
