require 'moonrope/version'

require 'moonrope/core_dsl'
require 'moonrope/eval_environment'

require 'moonrope/structures/structure'
require 'moonrope/structures/structure_dsl'

require 'moonrope/controllers/controller'
require 'moonrope/controllers/controller_dsl'
require 'moonrope/controllers/action'
require 'moonrope/controllers/action_dsl'
require 'moonrope/controllers/action_result'

module Moonrope
  
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
