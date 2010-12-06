module StepUp
  autoload :CONFIG, 'step-up/config.rb'
  autoload :VERSION, 'step-up/version.rb'
  module Driver
    autoload :Git, 'step-up/driver/git.rb'
  end
  module Parser
    autoload :VersionMask, 'step-up/parser/version_mask.rb'
  end
end
