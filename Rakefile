task :default do
  $LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
  $LOAD_PATH.unshift(File.expand_path('../test', __FILE__))
  require 'test_helper'
end

task :generate_html do
  $LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
  require 'moonrope'
  require 'moonrope/html_generator'
  base = Moonrope::Base.load(File.expand_path('../example', __FILE__))
  generator = Moonrope::HtmlGenerator.new(base, File.expand_path('../templates/basic', __FILE__))
  generator.generate(File.expand_path("../html", __FILE__))
end
