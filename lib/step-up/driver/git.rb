module StepUp
  module Driver
    class Git
      include GitExtensions::Notes
      include ConfigShortcut
      attr_reader :mask
      def initialize
        @mask = Parser::VersionMask.new(__versioning.version_mask)
      end

      def self.last_version(commit_base = "HEAD", count_commits = false)
        @driver ||= new
        @driver.last_version_tag(commit_base, count_commits) || "%s+%s" % [@driver.mask.blank, "#{ @driver.commit_history(commit_base).size if count_commits }"]
      end

      def self.unversioned_notes(commit_base = nil, clean = false)
        options = {:mode => :with_objects}
        options.delete :mode if clean
        new.all_objects_with_notes(commit_base).unversioned_only.to_changelog(options)
      end

      def commit_history(commit_base, top = nil)
        top = "-n#{ top }" unless top.nil?
        `git log --pretty=oneline --no-color --no-notes #{ top } #{ commit_base }`.gsub(/^(\w+)\s.*$/, '\1').split("\n")
      end

      def commits_between(first_commit, last_commit = "HEAD")
        commit_history("#{ first_commit }..#{ last_commit }")
      end

      def all_tags
        `git tag -l`.split("\n")
      end

      def objects_with_notes_of(ref)
        `git notes --ref=#{ ref } list`.gsub(/^\w+\s(\w+)$/, '\1').split(/\n/)
      end

      def all_objects_with_notes(commit_base = nil)
        objects = commit_history(commit_base)
        objects_with_notes = {}.extend GitExtensions::NotesTransformation
        objects_with_notes.driver = self
        __notes_sections.names.each do |section|
          obj = objects_with_notes_of(section)
          obj = obj.collect { |object|
            pos = objects.index(object)
            pos.nil? ? nil : [pos, object]
          }.compact.sort.reverse
          objects_with_notes[section] = obj.collect{ |o| o.last }
        end
        objects_with_notes
      end

      def note_message(ref, commit)
        `git notes --ref=#{ ref } show #{ commit }`
      end

      def notes_messages(objects_with_notes)
        objects_with_notes.messages
      end

      def all_version_tags
        @version_tags ||= all_tags.map{ |tag| mask.parse(tag) }.compact.sort.map{ |tag| mask.format(tag) }.reverse
      end

      def steps_to_increase_version(part, commit_base = "HEAD")
        tag = last_version_tag(commit_base)
        tag = tag.sub(/\+$/, '')
        tag = mask.increase_version(tag, part)
        message = all_objects_with_notes(commit_base)
        commands = []
        commands << "git fetch"
        commands << "git tag -a -m \"#{ message.to_changelog }\" #{ tag }"
        commands << "git push --tags"
        commands + steps_for_archiving_notes(message, tag)
      end

      def last_version_tag(commit_base = "HEAD", count_commits = false)
        commits = commit_history(commit_base)
        all_version_tags.each do |tag|
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
        nil
      end

      def fetched_remotes(refs_type = 'heads')
        config = `git config --get-regexp 'remote'`.split(/\n/)
        config.collect{ |line|
          $1 if line =~ /^remote\.(\w+)\.fetch\s\+refs\/#{ refs_type }/
        }.compact.uniq.sort
      end
    end
  end
end
