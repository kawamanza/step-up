module LastVersion
  module Driver
    class Git
      def history_log commit_base, top = nil
        top = "-n#{ top }" unless top.nil?
        `git log --pretty=oneline --no-color --no-notes #{ top } #{ commit_base }`.gsub(/^(\w+)\s.*$/, '\1').split("\n")
      end
    end
  end
end
