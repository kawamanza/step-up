$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'lastversion'
require 'rspec'

Dir["#{File.expand_path('../support', __FILE__)}/*.rb"].each do |file|
  require file
end

