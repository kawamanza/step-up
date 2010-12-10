require 'yaml'
module StepUp
  CONFIG = {}

  def self.load_config path
    return CONFIG unless File.exists? path
    CONFIG.merge! YAML.load_file(path)
  rescue TypeError => e
    puts "could not load #{path}: #{e.inspect}"
  end

  load_config File.expand_path('../config/step-up.yml', __FILE__)
  load_config '.stepuprc' # from working folder
end
