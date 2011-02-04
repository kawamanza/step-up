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
    method_options %w(mask -M) => :string # stepup version show --mask development_hudson_build_0
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
      # creates .stepuprc file
      content = File.read(File.expand_path("../config/step-up.yml", __FILE__))
      if options[:update] || ! File.exists?(".stepuprc")
        say_status File.exists?(".stepuprc") ? :update : :create, ".stepuprc", :green
        File.open(".stepuprc", "w") do |f|
          f.write content
        end
      else
        say_status :skip, "Creating .stepuprc", :yellow
      end
      # add entry to .git/config
      remotes_with_notes = driver.fetched_remotes('notes')
      unfetched_remotes = driver.fetched_remotes - remotes_with_notes
      unless remotes_with_notes.any? || unfetched_remotes.empty?
        if unfetched_remotes.size > 1
          remote = choose(unfetched_remotes, "Which remote would you like to fetch notes?")
          return unless unfetched_remotes.include?(remote)
        else
          remote = unfetched_remotes.first
        end
        cmds = ["git config --add remote.#{ remote }.fetch +refs/notes/*:refs/notes/*"]
        print_or_run(cmds, false)
      end
      # Changing Gemfile
      if File.exists?("Gemfile")
        gem_file = File.read("Gemfile")
        if gem_file =~ /\bstep-up\b/
          say_status :skip, "Adding dependency to step-up on Gemfile", :yellow
        else
          say_status :update, "Adding dependency to step-up on Gemfile", :green
          content = File.read(File.expand_path(File.join(__FILE__, '..', '..', '..', 'templates', 'default', 'Gemfile')))
          stepup_dependency = template_render(content)
          File.open("Gemfile", "w") do |f|
            f.write gem_file
            f.write "\n" unless gem_file.end_with?("\n")
            f.write stepup_dependency
          end
        end
      else
        say_status :skip, "Gemfile not found", :yellow
      end
      # Creating lib/version.rb
      content = File.read(File.expand_path(File.join(__FILE__, '..', '..', '..', 'templates', 'default', 'lib', 'version.rb')))
      new_version_rb = template_render(content)
      Dir.mkdir('lib') unless File.exists?('lib')
      if File.exists?("lib/version.rb")
        version_rb = File.read("lib/version.rb")
        if version_rb =~ /\bStepUp\b/
          say_status :skip, "Creating lib/version.rb", :yellow
        else
          say_status :update, "Appending to lib/version.rb", :green
          File.open("lib/version.rb", "w") do |f|
            f.write version_rb
            f.write "\n" unless version_rb.end_with?("\n")
            f.write new_version_rb
          end
        end
      else
        say_status :create, "Creating lib/version.rb", :green
        File.open("lib/version.rb", "w") do |f|
          f.write new_version_rb
        end
      end
      # Creating lib/tasks/versioning.rake
      if File.exists?("lib/tasks/versioning.rake")
        say_status :skip, "Creating lib/tasks/versioning.rake", :yellow
      else
        say_status :create, "Creating lib/tasks/versioning.rake", :green
        content = File.read(File.expand_path(File.join(__FILE__, '..', '..', '..', 'templates', 'default', 'lib', 'tasks', 'versioning.rake')))
        content = template_render(content)
        Dir.mkdir('lib/tasks') unless File.exists?('lib/tasks')
        File.open("lib/tasks/versioning.rake", "w") do |f|
          f.write content
        end
      end
      # Appending .gitignore
      unless File.exists?(".gitignore") && File.read(".gitignore") =~ /^#{gsub_params['version_file']}$/
        run "echo #{gsub_params['version_file']} >> .gitignore"
      else
        say_status :skip, "Adding #{gsub_params['version_file']} to .gitignore", :yellow
      end
    end

    desc "changelog --top=<num> --format={default|wiki|html}", "show changelog from each version tag"
    method_options %w[top -n] => :numeric
    method_options %w[format -f] => :string
    def changelog
      log = []
      method_name = "changelog_format_#{ options[:format] }"
      method_name = "changelog_format_default" unless respond_to?(method_name)
      driver.all_version_tags.each_with_index do |tag, index|
        break if options[:top] && index >= options[:top]
        log << send(method_name, tag)
      end
      puts log.join("\n\n")
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

    def changelog_format_default(tag)
      tag_info = driver.version_tag_info(tag)
      created_at = tag_info[:date].strftime("%b/%d %Y %H:%M %z")
    "\033[0;33m#{tag} (#{created_at} by #{tag_info[:tagger]})\033[0m\n\n#{ tag_info[:message] }"
    end

    def changelog_format_html(tag)
      tag_info = driver.version_tag_info(tag)
      created_at = tag_info[:date].strftime("%b/%d %Y %H:%M %z")
      log = []
      log << "<h3 class=\"changelog_header\">#{tag} (#{created_at} by #{tag_info[:tagger]})</h3>"
      log << " <pre class=\"changelog_description\">"
      log << tag_info[:message].gsub(/^/, '  ')
      log << " </pre>"
      log << "<br/>"
      log.join("\n")
    end

    def changelog_format_wiki(tag)
      tag_info = driver.version_tag_info(tag)
      created_at = tag_info[:date].strftime("%b/%d %Y %H:%M %z")
      log = []
      log << "== #{tag} (#{created_at} by #{tag_info[:tagger]}) ==\n"
      log << tag_info[:message].gsub(/^(\s+)-/, '\1*')
      log.join("\n")
    end

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
        mask = options[:mask]
        mask = nil if mask !~ /0/
        puts driver(mask).last_version_tag("HEAD", true)
      end
    end

    def version_create
      level = options[:level] || version_levels.last
      message = get_notes(true, get_custom_message)
      message = edit_message(driver.class::VERSION_MESSAGE_FILE_PATH, message) unless options[:'no-editor']

      if message.strip.empty?
        puts "\ninvalid version message: too short"
        return
      end

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

    def driver(mask = nil)
      return StepUp::Driver::Git.new mask unless mask.nil?
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
      changelog_options[:custom_message] = custom_message
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
      opts = {:capture => false}
      if print
        steps.each{ |step| say_status :step, step, :green }
      else
        status = true
        steps.each do |step|
          if status
            status = run(step, opts)
            say_status(:fail, "Problems when running `#{step}` (exit status #{$?.exitstatus})", :red) unless status
          else
            say_status(:skip, step, :yellow)
          end
        end
        exit(1) unless status
      end
    end
    
    def get_custom_message
      message = options[:message]
      (message && !message.strip.empty?) ? message : nil
    end

    def gsub_params
      @gsub_params ||= {
        'stepup_version' => StepUp::VERSION,
        'version_file' => "CURRENT_VERSION",
        'version_blank' => driver.mask.blank
      }
    end

    def template_render(tmpl)
      tmpl.gsub(/\{\{(.*?)\}\}/){ |m| gsub_params[$1] || m }
    end
  end
end
