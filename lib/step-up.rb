module StepUp
  autoload :CONFIG, 'step-up/config.rb'
  autoload :VERSION, 'step-up/version.rb'
  module Driver
    autoload :Git, 'step-up/driver/git.rb'
  end
  autoload :GitExtensions, 'step-up/git_extensions.rb'
  autoload :RangedNotes, 'step-up/ranged_notes.rb'
  module Parser
    autoload :VersionMask, 'step-up/parser/version_mask.rb'
  end
end
