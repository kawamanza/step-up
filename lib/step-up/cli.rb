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

    desc "init", "adds .stepuprc to your project and prepare your local repository to use notes"
    def init
      content = File.read(File.expand_path("../config/step-up.yml", __FILE__))
      puts "#{File.exists?(".stepuprc") ? 'updating' : 'creating' } .stepuprc"
      File.open(".stepuprc", "w") do |f|
        f.write content
      end
      driver = StepUp::Driver::Git.new
      remotes_with_notes = driver.fetched_remotes('notes')
      unfetched_remotes = driver.fetched_remotes - remotes_with_notes
      unless remotes_with_notes.any? || unfetched_remotes.empty?
        if unfetched_remotes.size > 1
          puts "Too mutch remotes, please edit your .git/config and add 'fetch' attribute to the right remote"
          # TODO ask which remote will be used
        end
        remote = unfetched_remotes.first
        puts "Adding attribute bellow to .git/config (remote.#{ remote })"
        puts "  fetch = +refs/notes/*:refs/notes/*"
        `git config --add remote.#{ remote }.fetch +refs/notes/*:refs/notes/*`
      end
    end

    desc "notes [object]", "show notes for the next version"
    method_options :clean => :boolean
    def notes(commit_base = nil)
      puts StepUp::Driver::Git.unversioned_notes(commit_base, options[:clean])
    end
    
    desc "-v, --version", "show the last version of the gem"
    def gem_version
      puts StepUp::VERSION
    end
  end
end
