module StepUp
  module Parser
    class VersionMask
      attr_reader :mask
      attr_reader :to_regex, :regex
      def initialize(mask)
        raise ArgumentError if mask.nil? || mask =~ /[1-8]|[09][09]|9.+0/
        @mask = mask.scan(/(\D*)([09])/)
        @to_regex = ""
        @mask.each { |level| @to_regex << "(?:#{level.first.gsub(/([\\\.\*\?\{\}\(\)\[\]])/, '\\\\\1')}(\\d+))#{'?' if level.last == '9'}" }
        @regex = /^#{to_regex}$/
      end

      def parse(version)
        return unless version.is_a?(String)
        v = version.scan(regex).first
        v.nil? ? nil : v.collect(&:to_i)
      end

      def format(version)
        raise ArgumentError unless version.is_a?(Array) && version.size == mask.size
        v = []
        mask.each_with_index do |part, index|
          level = version[index] || 0
          raise ArgumentError unless level.is_a?(Integer)
          unless level.zero? && part.last == '9'
            v << "#{part.first}#{level}"
          end
        end
        v.join
      end

      def increase_version(version, level)
        v = parse version
        level = CONFIG.versioning.version_levels.index(level)
        (v.size-level).times do |index|
          v[level+index] = (index.zero? ? (v[level+index] || 0) + 1 : nil)
        end
        format v
      end

      def blank
        format mask.size.times.map{ 0 }
      end
    end
  end
end
