module StepUp
  autoload :CONFIG, 'step-up/config.rb'
  autoload :VERSION, 'step-up/version.rb'
  autoload :Driver, 'step-up/driver.rb'
  autoload :GitExtensions, 'step-up/git_extensions.rb'
  autoload :RangedNotes, 'step-up/ranged_notes.rb'
  module Parser
    autoload :VersionMask, 'step-up/parser/version_mask.rb'
  end
end
