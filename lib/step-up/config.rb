require 'yaml'
module StepUp
  CONFIG = {}

  module ConfigExt
    def method_missing(m, *args, &block)
      super unless self.key?(m.to_s)
      value = self[m.to_s]
      if value.is_a?(Hash) && ! value.kind_of?(ConfigExt)
        class << value
          include ConfigExt
        end
      end
      value
    end
  end
  module ConfigSectionsExt
    def names
      map{ |section| section.is_a?(String) ? section : section["name"] }
    end

    def prefixes
      map{ |section| section.is_a?(String) ? to_prefix(section) : (section["prefix"] || to_prefix(section["name"])) }
    end

    def labels
      map{ |section| section.is_a?(String) ? to_label(section) : (section["label"] || to_label(section["name"])) }
    end

    def label(section)
      labels[names.index(section)]
    end

    private

    def to_prefix(name)
      "#{ (name.respond_to?(:singularize) ? name.singularize : name).gsub(/_/, ' ') }: "
    end

    def to_label(name)
      "#{ name.capitalize.gsub(/_/, ' ') }:"
    end
  end
  class << CONFIG
    include ConfigExt

    def notes_sections
      sections = notes.sections
      unless sections.kind_of?(ConfigSectionsExt)
        class << sections
          include ConfigSectionsExt
        end
      end
      sections
    end
  end

  def self.load_config(path)
    return CONFIG unless File.exists? path
    CONFIG.merge! YAML.load_file(path)
  rescue TypeError => e
    puts "could not load #{path}: #{e.inspect}"
  end

  load_config File.expand_path('../config/step-up.yml', __FILE__)
  load_config '.stepuprc' # from working folder
end
