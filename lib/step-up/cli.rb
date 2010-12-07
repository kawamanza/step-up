require 'thor'
require 'step-up'

module StepUp
  class CLI < Thor
    map %w(--version -v) => :gem_version
    
    default_task :version

    desc "", "show the last version of the application"
    def version
      puts StepUp::Driver::Git.last_version
    end
    
    desc "-v, --version", "show the last version of the gem"
    def gem_version
      puts StepUp::VERSION
    end
  end
end
