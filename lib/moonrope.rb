require 'json'
require 'moonrope/version'
require 'moonrope/base'
require 'moonrope/dsl'
require 'moonrope/eval_environment'
require 'moonrope/errors'
require 'moonrope/structures/structure'
require 'moonrope/structures/structure_dsl'
require 'moonrope/controllers/controller'
require 'moonrope/controllers/controller_dsl'
require 'moonrope/controllers/action'
require 'moonrope/controllers/action_dsl'
require 'moonrope/controllers/action_result'
require 'moonrope/controllers/before_action'
require 'moonrope/rack/middleware'
require 'moonrope/rack/request'
require 'moonrope/rack/param_set'

module Moonrope
  
  class << self
    
    def rack_path_prefix
      @path_prefix ||= 'api'
    end
    
    def rack_authenticator
      @rack_authenticator || nil
    end
    
  end
  
  #
  # Set a set of global variables for the duration of the 
  # provided block. If no block is passed, return all the
  # currently set globals.
  #
  def self.globals(options = {}, &block)
    if block_given?
      begin
        Thread.current[:moonrope_globals] = options
        yield
      ensure
        Thread.current[:moonrope_globals] = nil
      end
    else
      Thread.current[:moonrope_globals] || {}
    end
  end
  
end
