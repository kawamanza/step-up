module StepUp
  module Driver
    class Git < Base
      VERSION_MESSAGE_FILE_PATH = ".git/TAG_EDITMSG"
      NOTE_MESSAGE_FILE_PATH = ".git/NOTE_EDITMSG"
      
      include GitExtensions::Notes

      def unsupported_scm_banner
        if `git --version`.chomp =~ /\d\.[^\s]+/
          v = $&
          if Gem::Version.correct?(v)
            if Gem::Version.new("1.7.1") > Gem::Version.new(v)
              "Unsupported installed GIT version: #{v}\n" +
              "Please install version 1.7.1 or newer"
            end
          else
            "Installed GIT version unknown: #{v}"
          end
        else
          super
        end
      end

      def self.last_version
        new.last_version_tag
      end

      def empty_repository?
        `git branch`.empty?
      end

      def commit_history(commit_base, *args)
        return [] if empty_repository?
        options = args.last.is_a?(Hash) ? args.pop : {}
        top = args.shift
        top = "-n#{ top }" unless top.nil?
        encoding = CONFIG["log_output_encoding"] || "ISO-8859-1"
        commits = `git log --pretty=oneline --encoding=#{ encoding } --no-color #{ top } #{ commit_base }`
        commits.force_encoding(encoding) if RUBY_VERSION.to_f >= 1.9
        begin
          if options[:with_messages]
            commits.scan(/^(\w+)\s+(.*)$/)
          else
            commits.scan(/^(\w+)\s/).flatten
          end
        rescue ArgumentError => e
          if e.message.start_with?("invalid byte sequence")
            puts <<-MSG
Could not read information from git-log because of an #{e.message}.

To fix this you can insert an attribute "log_output_encoding" on
file .stepuprc into your GIT project. Example:

    \033[30;1m# .stepuprc\033[0m
    \033[32m+log_output_encoding: "ISO-8859-1"\033[0m
     notes:
       after_versioned:
         strategy: "keep" # Valid options: "keep" or "remove"
         \033[30;1m# ...\033[0m

To see the current encoding from your GIT repository, you may
check with the following bash command:

    `git log --pretty=oneline --no-color > test.txt && file test.txt && rm test.txt`

            MSG
            exit 1
          end
          raise
        end
      end

      def commits_between(first_commit, last_commit = "HEAD", *args)
        commit_base = first_commit.nil? ? last_commit : "#{ first_commit }..#{ last_commit }"
        commit_history(commit_base, *args)
      end

      def tags
        @tags ||= `git tag -l`
      end

      def objects_with_notes_of(ref)
        `git notes --ref=#{ ref } list`.scan(/\w+$/)
      end

      def note_message(ref, commit)
        `git notes --ref=#{ ref } show #{ commit }`
      end

      def all_version_tags
        @version_tags ||= tags.scan(mask.regex).map{ |tag| tag.collect(&:to_i) }.sort.map{ |tag| mask.format(tag) }.reverse
      end

      def version_tag_info(tag)
        full_message = `git show #{ tag } --no-decorate --quiet --date=default`
        tag_pattern = tag.gsub(/\./, '\\.')
        tag_message = full_message[/^tag\s#{tag_pattern}.*?\n\n(.*?)\n\n(?:tag\s[^\s]+|commit\s\w{40})\n/m, 1] || ""
        tagger = full_message[/\A.*?\nTagger:\s(.*?)\s</m, 1]
        date = Time.parse(full_message[/\A.*?\nDate:\s+(.*?)\n/m, 1])
        {:message => tag_message, :tagger => tagger, :date => date}
      end

      def detached_notes_as_hash(commit_base = "HEAD", notes_sections = nil)
        tag = all_version_tags.any? ? cached_last_version_tag(commit_base) : nil
        tag = tag.sub(/\+$/, '') unless tag.nil?
        RangedNotes.new(self, tag, commit_base, :notes_sections => notes_sections).notes.as_hash
      end

      def next_release_level(commit_base)
        level = CONFIG.versioning.version_levels.last
        if CONFIG.versioning["auto_increment"].is_a?(Hash)
          detached_notes = cached_detached_notes_as_hash(commit_base)
          CONFIG.versioning.version_levels.reverse.each do |name|
            sections = CONFIG.versioning.auto_increment.sections_level[name]
            next if sections.nil?
            level = name if detached_notes.any?{ |section, notes| sections.include?(section) && notes.any? }
          end
        end
        level
      end

      def next_version_tag(commit_base, level = nil)
        level = next_release_level(commit_base) if level.nil?
        if commit_base && mask.parse(commit_base)
          mask.increase_version(commit_base, level)
        else
          tag = cached_last_version_tag(commit_base)
          tag =~ /\+/ ? mask.increase_version($`, level) : nil
        end
      end

      def steps_to_increase_version(level, commit_base = "HEAD", message = nil)
        new_tag = next_version_tag(commit_base, level)
        notes = cached_detached_notes_as_hash(commit_base)
        commands = []
        commands << "git fetch" if cached_fetched_remotes.any?
        commands << "git tag -a -m \"#{ (message || notes.to_changelog).gsub(/([\$\\"`])/, '\\\\\1') }\" #{ new_tag } #{ commit_base }"
        commands << "git push #{cached_fetched_remotes("notes").first} refs/tags/#{new_tag}" if cached_fetched_remotes.any?
        commands + steps_for_archiving_notes(notes, new_tag)
      end

      def last_version_tag(commit_base = "HEAD", count_commits = false)
        all_versions = all_version_tags
        unless all_versions.empty?
          commits = cached_commit_history(commit_base)
          all_versions.each do |tag|
            commit_under_the_tag = commit_history(tag, 1).first
            index = commits.index(commit_under_the_tag)
            unless index.nil?
              unless index.zero?
                count = count_commits == true ? commits_between(tag, commit_base).size : 0
                tag = "#{ tag }+#{ count unless count.zero? }"
              end
              return tag
            end
          end
          count_commits == true ? zero_version(commit_base, true) : nil
        else
          zero_version(commit_base, count_commits)
        end
      end

      def fetched_remotes(refs_type = 'heads')
        config = `git config --get-regexp 'remote'`.split(/\n/)
        config.collect{ |line|
          $1 if line =~ /^remote\.(\w+)\.fetch\s\+refs\/#{ refs_type }/
        }.compact.uniq.sort
      end

      def editor_name
        ENV["GIT_EDITOR"] || ENV["EDITOR"] || `git config core.editor`.chomp
      end

      def zero_version(commit_base = "HEAD", count_commits = false)
        "%s+%s" % [mask.blank, "#{ commit_history(commit_base).size if count_commits }"]
      end
    end
  end
end
