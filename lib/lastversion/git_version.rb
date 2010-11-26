module LastVersion
  class GitVersion
    def self.verify!
      new.verify
    end

    def verify
      last_tag || "v0.0.0+"
    end

    TAG_PATTERN = /^v\d+\.\d+(\.\d+)?(\.\d+)?(rc\d+)?$/
    def version_array versions
      return unless versions.match(TAG_PATTERN)
      versions = versions.scan(/\d+/).collect(&:to_i)
      while versions.size < 5
        versions << 0
      end
      versions
    end

    def version_str versions
      while versions.any? && versions.last.zero? && versions.size > 3
        versions.pop
      end
      versions[4] = "rc#{ versions[4] }" if versions.size == 5
      versions.delete(3) if versions.size > 3 && versions[3].zero?
      version = "v" + versions.join('.')
      version = version.sub(/\.(rc\d+)$/, '\1') if versions.size == 5
      version
    end

    def sort_tags list
      list.collect{|v| version_array v }.sort
    end

    def last_tag commit = nil
      all_parent_commits = `git log --oneline --no-color #{ commit }`.gsub(/^(\w+)\s.*$/, '\1').split("\n")
      verified = []
      all_parent_commits.each_with_index do |c, i|
        tags = sort_tags(`git tag --contains #{ c }`.split("\n")).reverse
        tags.each do |tag|
          tag1 = version_str(tag)
          unless verified.include?(tag)
            verified << tag
            c1 = `git log --oneline --no-color -n1 #{ tag1 }`.gsub(/^(\w+)\s.*$/, '\1').split("\n").first
            return "#{ tag1 }#{ '+' if i > 0 }" if c1 == c
          end
        end
      end
      nil
    end
  end
end
