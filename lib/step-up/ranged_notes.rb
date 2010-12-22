module StepUp
  class RangedNotes
    COMMIT_NOTE = 0
    NOTE = 1

    attr_reader :driver, :first_commit, :last_commit

    def initialize(driver, first_commit = nil, last_commit = "HEAD")
      @driver = driver
      @last_commit = driver.commit_history(last_commit, 1).first
      first_commit = driver.commit_history(first_commit, 1).first unless first_commit.nil?
      raise ArgumentError, "The object #{ first_commit.inspect } was not found" unless first_commit.nil? || all_commits.include?(first_commit)
      @first_commit = first_commit
    end

    def notes
      (visible_detached_notes + scoped_commit_notes).sort.reverse.extend NotesArray
    end

    def all_notes
      (visible_detached_notes + scoped_attached_notes + scoped_commit_notes).sort.reverse.extend NotesArray
    end

    def all_commits
      @all_commits ||= driver.commit_history(last_commit)
    end

    def scoped_commits
      @scoped_commits ||= driver.commits_between(first_commit, last_commit, :with_messages => true).compact
    end

    def scoped_tags
      unless defined? @scoped_tags
        tags = []
        commits = scoped_commits.collect(&:first)
        driver.all_version_tags.each do |version_tag|
          object = driver.commit_history(version_tag, 1).first
          tags << version_tag if commits.include?(object)
        end
        @scoped_tags = tags
      end
      @scoped_tags
    end

    protected

    def versioned_objects
      unless defined? @versioned_objects
        notes = []
        all_notes_of_section(CONFIG.notes.after_versioned.section, all_commits).each{ |note| notes << note }
        @versioned_objects = notes
      end
      @versioned_objects
    end

    def all_visible_notes
      unless defined? @all_visible_notes
        notes = []
        CONFIG.notes_sections.names.each do |section|
          all_notes_of_section(section, all_commits).each{ |note| notes << note }
        end
        @all_visible_notes = notes
      end
      @all_visible_notes
    end

    def visible_detached_notes
      all_visible_notes.select do |note|
        not versioned_objects.any?{ |object| object[3] == note[3] }
      end
    end

    def scoped_attached_notes
      return [] if scoped_tags.empty?
      version_tags = scoped_tags.map{ |tag| tag.gsub(/([\.\*\?\{\}])/, '\\\\\1') }.join('|')
      matcher = /^#{ CONFIG.notes.after_versioned.changelog_message.gsub(/([\.\*\?\{\}])/, '\\\\\1').sub(/\\\{version\\\}/, "(?:#{ version_tags })") }$/

      all_visible_notes.select do |note|
        versioned_objects.any?{ |object| object[3] == note[3] && object[4] =~ matcher }
      end
    end

    def scoped_commit_notes
      prefixes = CONFIG.notes_sections.prefixes
      sections = CONFIG.notes_sections.names
      notes = []
      scoped_commits.each do |commit|
        message = commit.last
        prefixes.each_with_index do |prefix, index|
          message = message[prefix.size..-1] if message.start_with?(prefix)
          message.sub!(/\s*##{sections[index]}[\s\n]*\z/, '')
          if message != commit.last
            notes << [all_commits.index(commit.first), sections[index], COMMIT_NOTE, commit.first, message]
            break
          end
        end
      end
      notes
    end

    private

    def all_notes_of_section(section, commits = nil)
      notes = []
      commits = scoped_commits.collect(&:first) if commits.nil?
      driver.objects_with_notes_of(section).each do |commit|
        if commits.include?(commit)
          message = driver.note_message(section, commit)
          notes << [all_commits.index(commit), section, NOTE, commit, message]
        end
      end
      notes
    end

  end

  module NotesArray
    def as_hash
      notes = {}
      each do |note|
        notes[note[1]] ||= []
        notes[note[1]] << [note[3], note[4]] unless notes[note[1]].any?{ |n| n[0] == note[3] }
      end
      notes
    end
  end
end
