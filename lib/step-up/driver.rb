module StepUp
  module Driver
    autoload :Git, 'step-up/driver/git.rb'
    class Base
      attr_reader :mask
      def initialize(mask = nil)
        @mask = Parser::VersionMask.new(mask || CONFIG.versioning.version_mask)
      end
    end
  end
end
