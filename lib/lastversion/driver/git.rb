module LastVersion
  module Driver
    class Git
      attr_reader :mask
      def initialize
        @mask = Parser::VersionMask.new(CONFIG["versioning"]["version_mask"])
      end

      def self.last_version_tag commit_base = nil
        @driver ||= new
        @driver.last_tag(commit_base) || "%s%s" % [@driver.mask.blank, '+']
      end

      def commit_history commit_base, top = nil
        top = "-n#{ top }" unless top.nil?
        `git log --pretty=oneline --no-color --no-notes #{ top } #{ commit_base }`.gsub(/^(\w+)\s.*$/, '\1').split("\n")
      end

      def all_tags
        `git tag -l`.split("\n")
      end

      def objects_with_notes_of ref
        `git notes --ref=#{ ref } list`.gsub(/^\w+\s(\w+)$/, '\1').split(/\n/)
      end

      def all_objects_with_notes commit_base = nil
        objects = commit_history(commit_base)
        objects_with_notes = {}
        notes_sections.each do |section|
          obj = objects_with_notes_of(section)
          obj = obj.collect { |object|
            pos = objects.index(object)
            pos.nil? ? nil : [pos, object]
          }.compact.sort.reverse
          objects_with_notes[section] = obj.collect{ |o| o.last }
        end
        objects_with_notes
      end

      def note_message ref, commit
        `git notes --ref=#{ ref } show #{ commit }`
      end

      def notes_messages objects_with_notes
        notes = {}
        notes_sections.each do |section|
          notes[section] = (objects_with_notes[section] || []).map{ |commit| note_message(section, commit) }
        end
        notes
      end

      def all_version_tags
        @version_tags ||= all_tags.map{ |tag| mask.parse(tag) }.compact.sort.map{ |tag| mask.format(tag) }.reverse
      end

      def last_tag commit_base = nil
        objects = commit_history(commit_base)
        all_version_tags.each do |tag|
          index = objects.index(commit_history(tag, 1).first)
          return "#{ tag }#{ '+' unless index.zero? }" unless index.nil?
        end
        nil
      end

      private

      def notes_sections
        CONFIG["notes"]["sections"]
      end
    end
  end
end
