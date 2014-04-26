require 'json'
require 'moonrope/version'
require 'moonrope/base'
require 'moonrope/dsl'
require 'moonrope/eval_environment'
require 'moonrope/errors'
require 'moonrope/param_set'
require 'moonrope/request'
require 'moonrope/structures/structure'
require 'moonrope/structures/structure_dsl'
require 'moonrope/controllers/controller'
require 'moonrope/controllers/controller_dsl'
require 'moonrope/controllers/action'
require 'moonrope/controllers/action_dsl'
require 'moonrope/controllers/action_result'
require 'moonrope/controllers/before_action'
require 'moonrope/rack/middleware'



module Moonrope
  
  class << self
    
    def rack_path_prefix
      @path_prefix ||= 'api'
    end

  end
  
end
