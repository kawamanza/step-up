require 'thor'
require 'step-up'

module StepUp
  class CLI < Thor
    include Thor::Actions
    map %w(--version -v) => :gem_version  # $ stepup [--version|-v]
    
    default_task :version

    desc "version ACTION [OPTIONS]", "manage versions of your project"
    method_options %w(levels -L) => :boolean # $ stepup version [--levels|-L]
    method_options %w(level -l) => :string, %w(steps -s) => :boolean  # $ stepup version create [--level|-l] <level-name> [--steps|-s]
    VERSION_ACTIONS = %w[show create help]
    def version(action = nil)
      action = "show" unless VERSION_ACTIONS.include?(action)
      if self.respond_to?("version_#{action}")
        send("version_#{action}")
      else
        puts "invalid action: #{action}"
      end
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
    method_options :clean => :boolean, :steps => :boolean, :"-m" => :string, :since => :string
    def notes(action = "show", commit_base = nil)
      unless %w[show add remove help].include?(action)
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
      driver = StepUp::Driver::Git.new
      tag = options[:since] || driver.last_version_tag
      if tag =~ /[1-9]/
        tag = tag.gsub(/\+\d*$/, '')
      else
        tag = nil
      end
      ranged_notes = StepUp::RangedNotes.new(driver, tag, "HEAD")
      changelog_options = {}
      changelog_options[:mode] = :with_objects unless options[:clean]
      puts "Showing notes since #{ options[:since] }#{ " (including notes of tags: #{ ranged_notes.scoped_tags.join(", ")})" if ranged_notes.scoped_tags.any? }" unless options[:since].nil?
      puts "---"
      puts (options[:since].nil? ? ranged_notes.notes : ranged_notes.all_notes).as_hash.to_changelog(changelog_options)
    end

    def notes_remove(commit_base)
      commit_base = "HEAD" if commit_base.nil?
      driver = StepUp::Driver::Git.new
      ranged_notes = StepUp::RangedNotes.new(driver, nil, commit_base)
      notes = ranged_notes.notes_of(ranged_notes.last_commit).as_hash
      sections = notes.keys
      if sections.empty?
        puts "No notes found"
      else
        if sections.size > 1
          section = choose(sections, "Which section you want to remove notes?")
          return unless sections.include?(section)
        else
          section = sections.first
        end
        steps = driver.steps_to_remove_notes(section, ranged_notes.last_commit)
        print_or_run(steps, options[:steps])
      end
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
        print_or_run(steps, options[:steps])
      end
    end

    def version_show
      if options[:levels]
        puts "Current version levels:"
        version_levels.each  do |level|
          puts " - #{level}"
        end
      else
        driver = StepUp::Driver::Git.new
        puts driver.last_version_tag("HEAD", true)
      end
    end

    def version_create
      level = options[:level] || version_levels.last
      if version_levels.include? level
        driver = StepUp::Driver::Git.new
        steps = driver.steps_to_increase_version(level)
        print_or_run(steps, options[:steps])
      else
        puts "invalid version create option: #{level}"
      end
    end
    
    private

    def choose(list, statement)
      puts statement
      list.each_with_index do |item, index|
        puts "  #{ index + 1 }. #{ item }"
      end
      value = ask(">>")
      if value =~ /^\d+$/
        value = value.to_i
        value > 0 && list.size > value - 1 ? list[value - 1] : nil
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

    def version_levels
      CONFIG["versioning"]["version_levels"]
    end
    
    def print_or_run(steps, print)
      if print
        puts steps.join("\n")
      else
        steps.each do |step|
          run step
        end
      end
    end
    
  end
end
