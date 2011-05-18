require 'thor'
require 'step-up'

module StepUp
  class CLI < Thor
    attr_reader :commit_object
    include Thor::Actions
    map %w(--version -v) => :gem_version  # $ stepup [--version|-v]
    
    default_task :version

    desc "version ACTION [base_object] [OPTIONS]", "manage versions of your project"
    method_options %w(levels -L) => :boolean # $ stepup version [--levels|-L]
    method_options %w(level -l) => :string, %w(steps -s) => :boolean, %w(message -m) => :string, :'no-editor' => :boolean  # $ stepup version create [--level|-l <level-name>] [--steps|-s] [--message|-m <comment-string>] [--no-editor]
    method_options %w(mask -M) => :string # stepup version show --mask development_hudson_build_0
    method_options %w(masks) => :string # stepup version show --masks
    VERSION_ACTIONS = %w[show create help]
    def version(action = nil, commit_base = nil)
      unless VERSION_ACTIONS.include?(action)
        commit_base ||= action
        action = "show"
      end
      @commit_object = commit_base
      if self.respond_to?("version_#{action}")
        send("version_#{action}")
      else
        puts "invalid action: #{action}"
      end
    end

    desc "init", "Prepare your project to use stepup"
    method_options :update => :boolean
    method_options :gemfile => :boolean
    method_options :version_file_support => :boolean
    def init
      init_create_stepuprc
      init_update_gemfile if options[:gemfile]
      if options[:version_file_support]
        init_update_version_helper
        init_update_rakefile
        init_update_capfile
        init_update_gitignore
      end
    end

    desc "changelog --top=<num> --format={default|wiki|html}", "show changelog from each version tag"
    method_options %w[top -n] => :numeric
    method_options %w[format -f] => :string
    method_options %w(mask -M) => :string # stepup changelog --mask development_hudson_build_0
    def changelog
      log = []
      method_name = "changelog_format_#{ options[:format] }"
      method_name = "changelog_format_default" unless respond_to?(method_name)
      driver = driver(options[:mask])
      driver.all_version_tags.each_with_index do |tag, index|
        break if options[:top] && index >= options[:top]
        log << send(method_name, tag, driver.version_tag_info(tag))
      end
      puts log.join("\n\n")
    end

    desc "notes ACTION [base_object] [OPTIONS]", "show notes for the next version"
    method_options :clean => :boolean, :steps => :boolean, :"-m" => :string, :since => :string, :after => :string, :upto => :string
    method_options :fetch => :boolean
    method_options :"with-commit" => :boolean
    method_options %w[section -s] => :string
    method_options :sections => :array
    def notes(action = "show", commit_base = nil)
      unless %w[show add remove help].include?(action)
        commit_base ||= action
        action = "show"
      end
      @commit_object = commit_base
      if self.respond_to?("notes_#{action}")
        check_notes_config && send("notes_#{action}")
      else
        puts "invalid action: #{action}"
        exit(1)
      end
    end
    
    desc "-v, --version", "show the last version of the gem"
    def gem_version
      puts StepUp::VERSION
    end

    protected

    def changelog_format_default(tag, tag_info)
      created_at = tag_info[:date].strftime("%b/%d %Y %H:%M %z")
    "\033[0;33m#{tag} (#{created_at} by #{tag_info[:tagger]})\033[0m\n\n#{ tag_info[:message] }"
    end

    def changelog_format_html(tag, tag_info)
      created_at = tag_info[:date].strftime("%b/%d %Y %H:%M %z")
      log = []
      log << "<h3 class=\"changelog_header\">#{tag} (#{created_at} by #{tag_info[:tagger]})</h3>"
      log << " <pre class=\"changelog_description\">"
      log << tag_info[:message].gsub(/^/, '  ')
      log << " </pre>"
      log << "<br/>"
      log.join("\n")
    end

    def changelog_format_wiki(tag, tag_info)
      created_at = tag_info[:date].strftime("%b/%d %Y %H:%M %z")
      log = []
      log << "== #{tag} (#{created_at} by #{tag_info[:tagger]}) ==\n"
      log << tag_info[:message].gsub(/^(?:\t\t|\s\s\s\s)-\s/, "** ").gsub(/^(?:\t|\s\s)-\s/, "* ")
      log.join("\n")
    end

    def notes_show
      if options[:since] && options[:after]
        puts "conflict of options: --since and --after cannot be used together\n"
        exit(1)
      end

      initial_tag = options[:since] || options[:after]
      if initial_tag && options[:upto] && initial_tag > options[:upto]
        puts "conflict of options: --since value #{initial_tag} is greater than --after value #{options[:upto]}\n"
        exit(1)
      end

      message = []
      if initial_tag || options[:upto]
        message_header = "Showing notes "
        if initial_tag
          option = options[:since] ? "since" : "after"
          message_header << "#{option} #{ initial_tag } "
        end
        message_header <<  "up to #{  options[:upto] } " if  options[:upto]
        message_header << "(including notes of tags: #{ ranged_notes.scoped_tags.join(", ")})" if ranged_notes.scoped_tags.any?
        message << message_header
      end

      message << "---"
      message << get_notes
      puts message.join("\n")
    end

    def notes_remove
      ranged_notes = StepUp::RangedNotes.new(driver, nil, commit_object || "HEAD")
      notes = ranged_notes.notes_of(ranged_notes.last_commit).as_hash
      sections = notes.keys
      if sections.empty?
        puts "No notes found"
        exit(1)
      end
      section = options[:section]
      if section.nil?
        if sections.size > 1
          section = choose(sections, "Which section you want to remove notes?")
        else
          section = sections.first
        end
      end
      unless sections.include?(section)
        puts "Aborting due to invalid section"
        exit(1)
      end
      steps = driver.steps_to_remove_notes(section, ranged_notes.last_commit)
      print_or_run(steps, options[:steps])
    end

    def notes_add
      message = options[:m] 
      message = nil if options[:m] =~ /^(|m)$/

      unless message
        last_commit = driver.commit_history(commit_object, 1, :with_messages => true).first
        message = last_commit.last if last_commit
        message << <<-TEXT


# Please enter the note message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the operation.
        TEXT
        message = edit_message(driver.class::NOTE_MESSAGE_FILE_PATH, message)
      end
      
      unless message.nil? || message.empty?
        section = options[:section] || choose(CONFIG.notes_sections.names, "Choose a section to add the note:")
        if section.nil? || ! CONFIG.notes_sections.names.include?(section)
          puts "Aborting due to invalid section"
          exit(1)
        end
        steps = driver.steps_for_add_notes(section, message, commit_object)
        print_or_run(steps, options[:steps])
      end
    end

    def version_show
      if options[:levels]
        puts "Current version levels:"
        version_levels.each  do |level|
          puts " - #{level}"
        end
      elsif options[:masks]
        all_tags = driver.tags.scan(/[^\r\n]+/)
        all_masks = all_tags.map{ |tag| tag.gsub(/\d+/, '0') }.uniq.sort
        masks = []
        prev = nil
        all_masks.each do |mask|
          next unless mask =~ /\d$/
          mask = masks.pop + mask[prev.size..-1].gsub(/0/, '9') if prev && mask.start_with?(prev.gsub(/9/, '0'))
          masks << (prev = mask)
        end
        puts masks.join("\n") if masks.any?
      else
        mask = options[:mask]
        mask = nil if mask !~ /0/
        puts driver(mask).last_version_tag(commit_object || "HEAD", true)
      end
    end

    def version_create
      level = options[:level] || "auto"
      message = get_notes(true, get_custom_message)

      if level == "auto" && CONFIG.versioning["auto_increment"].is_a?(Hash)
        detached_notes = driver.cached_detached_notes_as_hash(commit_object || "HEAD")
        level = version_levels.last
        version_levels.reverse.each do |name|
          sections = CONFIG.versioning.auto_increment.sections_level[name]
          next if sections.nil?
          level = name if detached_notes.any?{ |section, notes| sections.include?(section) && notes.any? }
        end
      end

      if version_levels.include? level
        unless options[:'no-editor']
          message << <<-TEXT


# Please enter the log message for your tag. Lines starting
# with '#' will be ignored, and an empty message aborts the operation.
# You are about to increase the '#{level}' version level.
          TEXT
          message = edit_message(driver.class::VERSION_MESSAGE_FILE_PATH, message)
        end

        if message.strip.empty?
          puts "Aborting due to empty log message"
          exit(1)
        end
        steps = driver.steps_to_increase_version(level, commit_object || "HEAD", message)
        print_or_run(steps, options[:steps])
      else
        puts "invalid version create option: #{level}"
        exit(1)
      end
    end
    
    
    def init_create_stepuprc
      content = File.read(File.expand_path("../config/step-up.yml", __FILE__))
      if options[:update] || ! File.exists?(".stepuprc")
        say_status File.exists?(".stepuprc") ? :update : :create, ".stepuprc", :green
        File.open(".stepuprc", "w") do |f|
          f.write content
        end
      else
        say_status :skip, "Creating .stepuprc", :yellow
      end      
    end
    
    def init_update_gemfile
      if File.exists?("Gemfile")
        gem_file = File.read("Gemfile")
        if gem_file =~ /\bstep-up\b/
          regex = /^(\s*gem\s+(?:'step-up'|"step-up")\s*,\s*['"])((?:~>|=>|=)\s*.*?)(['"])/
          if gem_file =~ regex && ! $2.end_with?(StepUp::VERSION)
            say_status :update, "Updating dependency to step-up on Gemfile", :green
            File.open("Gemfile", "w") do |f|
              f.write gem_file.gsub(regex, '\1~> '+StepUp::VERSION+'\3')
            end
          else
            say_status :skip, "Adding dependency to step-up on Gemfile", :yellow
          end
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
    end
    
    def init_update_version_helper
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
    end

    def init_update_rakefile
      if File.exists?("Rakefile")
        content = File.read(File.expand_path(File.join(__FILE__, '..', '..', '..', 'templates', 'default', 'Rakefile')))
        content = template_render(content)
        if File.exists?("lib/tasks/versioning.rake") && File.read("lib/tasks/versioning.rake") =~ /\bstep-up\b/
          content = File.read("lib/tasks/versioning.rake")
          say_status :remove, "Removing lib/tasks/versioning.rake", :blue
          `rm lib/tasks/versioning.rake`
        end
        rake_file = File.read("Rakefile")
        if rake_file =~ /\bstep-up\b/
          say_status :skip, "Appending to Rakefile", :yellow
        else
          say_status :update, "Appending to Rakefile", :green
          File.open("Rakefile", "w") do |f|
            f.write rake_file
            f.write "\n" unless rake_file.end_with?("\n")
            f.write content
          end
        end
      end
    end

    def init_update_capfile
      if File.exists?("Capfile") && File.exists?("Rakefile")
        content = File.read(File.expand_path(File.join(__FILE__, '..', '..', '..', 'templates', 'default', 'Capfile')))
        content = template_render(content)
        cap_file = File.read("Capfile")
        if cap_file =~ /\bstepup\b/
          say_status :skip, "Appending to Capfile", :yellow
        else
          say_status :update, "Appending to Capfile", :green
          File.open("Capfile", "w") do |f|
            f.write cap_file
            f.write "\n" unless cap_file.end_with?("\n")
            f.write content
          end
        end
      end
    end

    def init_update_gitignore
      unless File.exists?(".gitignore") && File.read(".gitignore") =~ /^#{gsub_params['version_file']}$/
        run "echo #{gsub_params['version_file']} >> .gitignore"
      else
        say_status :skip, "Adding #{gsub_params['version_file']} to .gitignore", :yellow
      end
    end
    
    private

    def edit_message(temp_file, initial_content)
      File.open(temp_file, "w"){ |f| f.write initial_content }
      editor = driver.editor_name
      if editor =~ /\w/
        init_time = Time.now
        if editor =~ /^vim?\b/
          system "#{ editor } #{ temp_file }"
        else
          `#{ editor } #{ temp_file } && wait $!`
        end
        elapsed_time = Time.now - init_time
        if elapsed_time < 1.0
          puts "Premature termination of the text editor."
          puts "Make sure of having set the editor as appropriate."
          exit 1
        end
        File.read(temp_file).gsub(/^\#.*/m, '').rstrip
      else
        puts <<-TEXT
No editor found.

  You can specify the editor by the following ways:
  - By git-config
    $ git config --global core.editor 'mate -w'
  - By environment variables
    $ export $GIT_EDITOR='mate -w'`
    #or
    $ export $EDITOR='mate -w'
TEXT
        exit 1
      end
    end

    def driver(mask = nil)
      return StepUp::Driver::Git.new mask unless mask.nil?
      @driver ||= StepUp::Driver::Git.new
    end

    def ranged_notes
      unless defined? @ranged_notes
        initial_tag = options[:since] || options[:after] || driver.cached_last_version_tag(commit_object || "HEAD")
        final_tag = options[:upto] || commit_object || "HEAD"
        
        if options[:upto] && !(options[:since] || options[:after])
          initial_tag = driver.all_version_tags.last
        end
        
        initial_tag = sanitize_tag_version(initial_tag)
        final_tag = sanitize_tag_version(final_tag)
        @ranged_notes = StepUp::RangedNotes.new(driver, initial_tag, final_tag, :exclude_initial_tag_notes => options[:after], :notes_sections => options[:sections])
      end
      @ranged_notes
    end

    def sanitize_tag_version(tag)
      tag =~ /[1-9]/ ? tag.gsub(/\+\d*$/, '') : nil
    end

    def get_notes(clean = options[:clean], custom_message = nil)
      notes_options = {}
      notes_options[:mode] = :with_objects unless clean || clean.nil? && ! options[:"with-commit"]
      notes_options[:custom_message] = custom_message
      notes_hash = (options[:since].nil? && options[:after].nil? ? driver.cached_detached_notes_as_hash(commit_object || "HEAD", options["sections"]) : ranged_notes.all_notes.as_hash)
      notes_hash.to_changelog(notes_options)
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
      CONFIG.versioning.version_levels
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

    def check_notes_config
      return true if driver.cached_fetched_remotes.empty?
      remotes_with_notes = driver.fetched_remotes('notes')
      unfetched_remotes = driver.cached_fetched_remotes - remotes_with_notes
      cmds = []
      unless remotes_with_notes.any? || unfetched_remotes.empty?
        answer = options[:fetch] ? "yes" : raw_ask("To perform this operation you need some additional fetch instruction on your git-config file.\nMay stepup add the missing instruction for you? [yes/no]:")
        return false unless answer == "yes"
        if unfetched_remotes.size > 1
          remote = choose(unfetched_remotes, "Which remote would you like to fetch notes?")
          return false unless unfetched_remotes.include?(remote)
        else
          remote = unfetched_remotes.first
        end
        cmds << "git config --add remote.#{remote}.fetch +refs/notes/*:refs/notes/*" unless remote.nil?
      end
      cmds << "git fetch #{remote}" if options[:fetch] || cmds.any?
      print_or_run(cmds, false) unless cmds.empty?
      true
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
