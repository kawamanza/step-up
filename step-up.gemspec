# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

version_file = File.expand_path "../GEM_VERSION", __FILE__
File.delete version_file if File.exists? version_file

require 'step-up'

Gem::Specification.new do |s|
  s.name        = "step-up"
  s.version     = StepUp::VERSION
  s.authors     = ["Marcelo Manzan", "Eric Fer"]
  s.email       = ["manzan@gmail.com", "eric.fer@gmail.com"]
  s.homepage    = "https://github.com/kawamanza/step-up"
  s.summary     = %q{The best way to manage your project's versioning}
  s.description = %q{StepUp manages a project's versioning through its entire lifecycle}

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "step-up"

  s.add_dependency "thor", ">= 0.14.6"

  s.add_development_dependency "rspec", "~> 2.11.0"
  s.add_development_dependency "mocha", "~> 0.12.0"
  s.add_development_dependency "rake", "~> 10.4.2"

  excepts = %w[
    .gitignore
    step-up.gemspec
  ]
  tests = `git ls-files -- {test,spec,features}/*`.split("\n")
  others = []
  others << "GEM_VERSION" if File.exists?(version_file)
  s.files              = `git ls-files`.split("\n") - excepts - tests + others
  s.test_files         = tests
  s.executables        = %w(stepup)
end
