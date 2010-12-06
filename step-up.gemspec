# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'step-up'

Gem::Specification.new do |s|
  s.name        = "step-up"
  s.version     = StepUp::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Marcelo Manzan", "Eric Adrien Fer"]
  s.email       = ["manzan@gmail.com", "eric.fer@gmail.com"]
  s.homepage    = "https://github.com/redoc/step-up"
  s.summary     = %q{The best way to manage your project's versioning}
  s.description = %q{StepUp manages a project's versioning through its entire life}

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "step-up"

  s.add_dependency "thor", ">= 0.14.6"

  s.add_development_dependency "rspec"
  s.add_development_dependency "mocha" 

  excepts = %w[
    .gitignore
    step-up.gemspec
  ]
  tests = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.files              = `git ls-files`.split("\n") - excepts - tests
  s.test_files         = tests
  s.executables        = %w(step-up)
  s.default_executable = "step-up"
  s.require_paths      = ["lib"]
end
