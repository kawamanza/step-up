module StepUp
  module GitExtensions
    NOTES_STRATEGIES = {}
    def self.register_notes_strategy(key, instance)
      NOTES_STRATEGIES[key] = instance
    end

    module Notes
      def steps_for_archiving_notes(objects_with_notes, tag)
        strategy = CONFIG.notes.after_versioned["strategy"] || "keep"
        raise ArgumentError, "unknown strategy: #{ strategy }" unless NOTES_STRATEGIES.include?(strategy)
        NOTES_STRATEGIES[strategy].steps_for_archiving_notes(objects_with_notes, tag, self)
      end

      def steps_for_add_notes(section, message, commit_base = nil)
        commands = []
        commands << "git fetch" if cached_fetched_remotes.any?
        commands << "git notes --ref=#{ section } add -m \"#{ message.gsub(/([\$\\"`])/, '\\\\\1') }\" #{ commit_base }"
        commands << "git push #{ notes_remote } refs/notes/#{ section }" if cached_fetched_remotes.any?
        commands
      end

      def steps_to_remove_notes(section, commit_base)
        commands = []
        commands << "git fetch" if cached_fetched_remotes.any?
        commands << "git notes --ref=#{ section } remove #{ commit_base }"
        commands << "git push #{ notes_remote } refs/notes/#{ section }" if cached_fetched_remotes.any?
        commands
      end

      def notes_remote
        fetched_remotes('notes').first
      end
    end

    module Strategy
      class RemoveNotes
        def steps_for_archiving_notes(objects_with_notes, tag, driver)
          commands = []
          STDERR.puts "WARN: the 'remove' strategy is no longer supported"
          commands
        end
      end

      class KeepNotes
        def steps_for_archiving_notes(objects_with_notes, tag, driver)
          commands = []
          objects = []
          changelog_message = CONFIG.notes.after_versioned.changelog_message
          CONFIG.notes_sections.names.each do |section|
            next unless objects_with_notes.has_key?(section)
            objects_with_notes[section].each do |object|
              next if object[2] == RangedNotes::COMMIT_NOTE
              unless objects.include?(object[0])
                objects << object[0]
                kept_message = changelog_message.gsub(/\{version\}/, tag)
                commands << "git notes --ref=#{ CONFIG.notes.after_versioned.section } add -m \"#{ kept_message.gsub(/([\$\\"])/, '\\\\\1') }\" #{ object[0] }"
              end
            end
          end
          commands << "git push #{ driver.notes_remote } refs/notes/#{ CONFIG.notes.after_versioned.section }" unless objects.empty? || driver.cached_fetched_remotes.empty?
          commands
        end
      end
    end
    register_notes_strategy "remove", Strategy::RemoveNotes.new
    register_notes_strategy "keep", Strategy::KeepNotes.new
  end
end
