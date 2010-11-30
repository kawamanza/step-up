module LastVersion
  module Driver
    class Git
      attr_reader :mask
      def initialize
        @mask = Parser::VersionMask.new(CONFIG["versioning"]["patterns"]["version"])
      end

      def history_log commit_base, top = nil
        top = "-n#{ top }" unless top.nil?
        `git log --pretty=oneline --no-color --no-notes #{ top } #{ commit_base }`.gsub(/^(\w+)\s.*$/, '\1').split("\n")
      end

      def all_tags
        `git tag -l`.split("\n")
      end

      def all_version_tags
        @version_tags ||= all_tags.map{ |tag| mask.parse(tag) }.compact.sort.map{ |tag| mask.format(tag) }.reverse
      end
    end
  end
end
