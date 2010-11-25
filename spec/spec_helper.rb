require 'rubygems'
require 'bundler'
require 'rspec'

Dir["#{File.expand_path('../support', __FILE__)}/*.rb"].each do |file|
  require file
end

