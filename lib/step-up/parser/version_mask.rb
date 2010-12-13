module StepUp
  module Parser
    class VersionMask
      attr_reader :mask
      attr_reader :iterator
      def initialize(mask)
        @mask = mask.scan(/\D+[09]/)
        raise ArgumentError if mask != @mask.join
        @iterator = @mask.map do |token|
          Regexp.new token.sub(/\./, '\\.').sub(/[09]$/,'(\d+)')
        end
      end

      def to_regex
        re = []
        mask.each_with_index do |part, index|
          re << "(?:#{ iterator[index].source })#{ '?' if part.end_with?('9') }"
        end
        re.join
      end

      def parse(version)
        return unless version.is_a?(String)
        i = 0
        v = []
        iterator.each_with_index do |pattern, index|
          pos = version.index(pattern, i)
          if pos.nil?
            if mask[index] =~ /9$/
              v << 0
            else
              return
            end
          else
            if pos == i
              n = $1
              i += mask[index].size + n.size - 1
              v << n.to_i
            elsif mask[index] =~ /9$/
              v << 0
            else
              return
            end
          end
        end
        v
      end

      def format(version)
        raise ArgumentError unless version.is_a?(Array) && version.size == mask.size
        v = []
        iterator.each_with_index do |pattern, index|
          part = version[index] || 0
          raise ArgumentError unless part.is_a?(Fixnum)
          unless part.zero? && mask[index] =~ /9$/
            v << mask[index].sub(/[09]$/, part.to_s)
          end
        end
        v.join
      end

      def increase_version(version, part)
        v = parse version
        part = version_parts.index(part)
        (v.size-part).times do |index|
          v[part+index] = (index.zero? ? (v[part+index] || 0) + 1 : nil)
        end
        format v
      end

      def blank
        format mask.size.times.map{ 0 }
      end

      private

      def version_parts
        CONFIG["versioning"]["version_parts"]
      end
    end
  end
end
