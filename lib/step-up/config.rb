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
  class << CONFIG
    include ConfigExt
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
