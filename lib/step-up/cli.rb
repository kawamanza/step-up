require 'thor'
require 'step-up'

module StepUp
  class CLI < Thor
    include Thor::Actions
    map %w(--version -v) => :gem_version  # $ stepup [--version|-v]
    
    default_task :version

    desc "version ACTION [OPTIONS]", "manage versions of your project"
    method_options %w(levels -L) => :boolean # $ stepup version [--levels|-L]
    method_options %w(level -l) => :string, %w(steps -s) => :boolean, %w(message -m) => :string, :'no-editor' => :boolean  # $ stepup version create [--level|-l <level-name>] [--steps|-s] [--message|-m <comment-string>] [--no-editor]
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
      remotes_with_notes = driver.fetched_remotes('notes')
      unfetched_remotes = driver.fetched_remotes - remotes_with_notes
      unless remotes_with_notes.any? || unfetched_remotes.empty?
        if unfetched_remotes.size > 1
          remote = choose(unfetched_remotes, "Which remote would you like to fetch notes?")
          return unless unfetched_remotes.include?(remote)
        else
          remote = unfetched_remotes.first
        end
        puts "Adding attribute below to .git/config (remote.#{ remote })"
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
      message = []
      message << "Showing notes since #{ options[:since] }#{ " (including notes of tags: #{ ranged_notes.scoped_tags.join(", ")})" if ranged_notes.scoped_tags.any? }" unless options[:since].nil?
      message << "---"
      message << get_notes
      puts message.join("\n")
    end

    def notes_remove(commit_base)
      commit_base = "HEAD" if commit_base.nil?
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
        section = choose(CONFIG.notes_sections.names, "Choose a section to add the note:")
        return if section.nil? || ! CONFIG.notes_sections.names.include?(section)
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
        puts driver.last_version_tag("HEAD", true)
      end
    end

    def version_create
      level = options[:level] || version_levels.last
      message = get_notes(true, options[:message])
      message = edit_message(driver.class::VERSION_MESSAGE_FILE_PATH, message) unless options[:'no-editor']

      if version_levels.include? level
        steps = driver.steps_to_increase_version(level, "HEAD", message)
        print_or_run(steps, options[:steps])
      else
        puts "invalid version create option: #{level}"
      end
    end
    
    private

    def edit_message(temp_file, initial_content)
      File.open(temp_file, "w"){ |f| f.write initial_content }
      editor = driver.editor_name
      if editor =~ /\w/
        if editor =~ /^vim?\b/
          system "#{ editor } #{ temp_file }"
        else
          `#{ editor } #{ temp_file } && wait $!`
        end
        File.read(temp_file).rstrip
      end
    end

    def driver
      @driver ||= StepUp::Driver::Git.new
    end

    def ranged_notes
      unless defined? @ranged_notes
        tag = options[:since] || driver.last_version_tag
        if tag =~ /[1-9]/
          tag = tag.gsub(/\+\d*$/, '')
        else
          tag = nil
        end
        @ranged_notes = StepUp::RangedNotes.new(driver, tag, "HEAD")
      end
      @ranged_notes
    end

    def get_notes(clean = options[:clean], custom_message = nil)
      changelog_options = {}
      changelog_options[:mode] = :with_objects unless clean
      changelog_options[:custom_message] ||= custom_message
      notes = (options[:since].nil? ? ranged_notes.notes : ranged_notes.all_notes)
      notes.as_hash.to_changelog(changelog_options)
    end

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
