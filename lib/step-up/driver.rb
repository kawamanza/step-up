module StepUp
  module Driver
    autoload :Git, 'step-up/driver/git.rb'
    class Base
      attr_reader :mask
      attr_reader :cache
      def initialize(mask = nil)
        @mask = Parser::VersionMask.new(mask || CONFIG.versioning.version_mask)
        @cache = {}
      end

      def method_missing(called_method, *args, &block)
        if called_method.to_s =~ /^cached_(.+)$/
          method = $1
          if respond_to?(method)
            if block_given?
              send(method, *args, &block)
            else
              cache[method] ||= {}
              cache[method][args] ||= send(method, *args)
            end
          else
            super
          end
        else
          super
        end
      end
    end
  end
end
