require 'moonrope/version'

require 'moonrope/core_dsl'
require 'moonrope/structures/eval_environment'
require 'moonrope/structures/structure'
require 'moonrope/structures/structure_dsl'

module Moonrope
  
  #
  # Set or get a set of global variables
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
