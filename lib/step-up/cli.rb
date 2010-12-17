require 'thor'
require 'step-up'

module StepUp
  class CLI < Thor
    include Thor::Actions
    map %w(--version -v) => :gem_version
    
    default_task :version

    desc "", "show the last version of the application"
    def version
      puts StepUp::Driver::Git.last_version("HEAD", true)
    end

    desc "init", "adds .stepuprc to your project and prepare your local repository to use notes"
    method_options :update => :boolean
    def init
      content = File.read(File.expand_path("../config/step-up.yml", __FILE__))
      if options[:update] || ! File.exists?(".stepuprc")
        puts "#{File.exists?(".stepuprc") ? 'updating' : 'creating' } .stepuprc"
        File.open(".stepuprc", "w") do |f|
          f.write content
        end
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

    desc "notes ACTION [object] [OPTIONS]", "show notes for the next version"
    method_options :clean => :boolean, :steps => :boolean, :"-m" => :string
    def notes(action = "show", commit_base = nil)
      unless %w[show add help].include?(action)
        commit_base ||= action
        action = "show"
      end
      if self.respond_to?("notes_#{action}")
        send("notes_#{action}", commit_base)
      else
        puts "invalid action: #{action}"
      end
    end
    
    desc "-v, --version", "show the last version of the gem"
    def gem_version
      puts StepUp::VERSION
    end

    protected

    def notes_show(commit_base = nil)
      puts StepUp::Driver::Git.unversioned_notes(commit_base, options[:clean])
    end

    def notes_add(commit_base = nil)
      message = options[:m] 
      message = nil if options[:m] =~ /^(|m)$/
      message ||= get_message("Note message:\n>>", " >")
      unless message.empty?
        driver = StepUp::Driver::Git.new
        section = choose(CONFIG["notes"]["sections"], "Choose a section to add the note:")
        return if section.nil? || ! CONFIG["notes"]["sections"].include?(section)
        steps = driver.steps_for_add_notes(section, message, commit_base)
        if options[:steps]
          puts steps.join("\n")
        else
          steps.each do |step|
            run step
          end
        end
      end
    end

    private

    def choose(list, enunciation)
      puts enunciation
      list.each_with_index do |item, index|
        puts "  #{ index + 1 }. #{ item }"
      end
      value = ask(">>")
      if value =~ /^\d+$/
        value = value.to_i
        value > 0 && list.size > value ? list[value - 1] : nil
      else
        value.empty? ? nil : value
      end
    end

    def get_message(prompt1, prompt2, total_breaks = 1)
      lines = []
      prompt = prompt1
      empty = total_breaks - 1
      line = nil
      begin
        lines << line unless line.nil?
        line = raw_ask(prompt)
        prompt = prompt2
        empty = line.empty? ? empty + 1 : 0
      end while empty < total_breaks
      lines.join("\n").gsub(/\n+\z/, '').gsub(/\A\n+/, '')
    end

    def raw_ask(statement, color = nil)
      say("#{statement} ", color)
      $stdin.gets.chomp
    end
  end
end
