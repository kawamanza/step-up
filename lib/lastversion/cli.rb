require 'thor'
require 'lastversion'

module LastVersion
  class CLI < Thor
    map %w(--version -v) => :gem_version
    
    default_task :version

    desc "", "show the last version of the application"
    def version
      puts LastVersion::Driver::Git.last_version
    end
    
    desc "-v, --version", "show the last version of the gem"
    def gem_version
      puts LastVersion::VERSION
    end
  end
end