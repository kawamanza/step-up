module StepUp
  module GitExtensions
    NOTES_STRATEGIES = {}
    def self.register_notes_strategy(key, instance)
      NOTES_STRATEGIES[key] = instance
    end

    module Notes
      def steps_for_archiving_notes(objects_with_notes, tag)
        strategy = notes_after_versioned["strategy"]
        raise ArgumentError, "unknown strategy: #{ strategy }" unless NOTES_STRATEGIES.include?(strategy)
        NOTES_STRATEGIES[strategy].steps_for_archiving_notes(objects_with_notes, tag, self)
      end

      private

      def notes_sections
        CONFIG["notes"]["sections"]
      end

      def notes_after_versioned
        CONFIG["notes"]["after_versioned"]
      end
    end

    module NotesTransformation
      def self.extend_object(base)
        super
        class << base
          attr_writer :driver, :parent, :kept_notes
          def []=(p1, p2)
            super
            sections << p1 unless sections.include?(p1)
          end
        end
      end

      def driver
        @driver ||= parent.driver
      end

      def sections
        @sections ||= parent != self && parent.sections && parent.sections.dup || []
      end

      def parent
        @parent ||= self
      end

      def kept_notes
        @kept_notes ||= driver.objects_with_notes_of(kept_notes_section)
      end

      def kept_notes_section
        driver.send(:notes_after_versioned)["section"]
      end

      def unversioned_only
        notes = {}.extend NotesTransformation
        notes.driver = driver
        notes.kept_notes = kept_notes
        sections.each do |section|
          notes[section] = (parent[section] || []).select{ |commit| not kept_notes.include?(commit) }
        end
        notes
      end

      def messages
        unless defined? @messages
          notes = {}.extend NotesTransformation
          notes.parent = self
          sections.each do |section|
            notes[section] = (parent[section] || []).map{ |commit| driver.note_message(section, commit) }
          end
          @messages = notes
        end
        @messages
      end

      def to_changelog(options = {})
        changelog = []
        sections.each_with_index do |section, index|
          changelog << "#{ section.capitalize.gsub(/_/, ' ') }:\n" unless index.zero? || messages[section].empty?
          messages[section].each_with_index do |note, index|
            note = note.sub(/$/, " (#{ parent[section][index] })") if options[:mode] == :with_objects
            changelog += note.split(/\n+/).collect{ |line| line.sub(/^(\s*)/, '\1  - ') }
          end
          changelog << "" unless messages[section].empty?
        end
        changelog.join("\n")
      end
    end

    module Strategy
      class RemoveNotes
        def steps_for_archiving_notes(objects_with_notes, tag, driver)
          commands = []
          objects_with_notes.sections.each do |section|
            objects_with_notes[section].each do |object|
              commands << "git notes --ref=#{ section } remove #{ object }"
            end
            commands << "git push origin refs/notes/#{ section }" unless objects_with_notes[section].empty?
          end
          commands
        end
      end

      class KeepNotes
        def steps_for_archiving_notes(objects_with_notes, tag, driver)
          commands = []
          objects = []
          changelog_message = driver.notes_after_versioned["changelog_message"]
          objects_with_notes.sections.each do |section|
            objects_with_notes[section].each do |object|
              unless objects.include?(object)
                objects << object
                kept_message = changelog_message.gsub(/\{version\}/, tag)
                commands << "git notes --ref=#{ driver.notes_after_versioned["section"] } add -m \"#{ kept_message }\" #{ object }"
              end
            end
          end
          commands << "git push origin refs/notes/#{ driver.notes_after_versioned["section"] }" unless objects.empty?
          commands
        end
      end
    end
    register_notes_strategy "remove", Strategy::RemoveNotes.new
    register_notes_strategy "keep", Strategy::KeepNotes.new
  end
end
