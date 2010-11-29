module LastVersion
  autoload :GitVersion, 'lastversion/git_version.rb'
  autoload :CONFIG, 'lastversion/config.rb'
  autoload :VERSION, 'lastversion/version.rb'
  module Driver
    autoload :Git, 'lastversion/driver/git.rb'
  end
end
