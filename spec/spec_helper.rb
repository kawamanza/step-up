$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'step-up'
require 'rspec'

Dir["#{File.expand_path('../support', __FILE__)}/*.rb"].each do |file|
  require file
end

RSpec.configure do |config|
  config.mock_with :mocha
end
