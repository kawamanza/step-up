module StepUp
  autoload :CONFIG, 'step-up/config.rb'
  autoload :ConfigShortcut, 'step-up/config_shortcut.rb'
  autoload :VERSION, 'step-up/version.rb'
  module Driver
    autoload :Git, 'step-up/driver/git.rb'
  end
  autoload :GitExtensions, 'step-up/git_extensions.rb'
  module Parser
    autoload :VersionMask, 'step-up/parser/version_mask.rb'
  end
end
