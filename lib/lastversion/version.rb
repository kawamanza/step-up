module LastVersion
  path = File.expand_path('../..', __FILE__)
  v = nil
  if path =~ /\/lastversion-([\w\.\-]+)/
    v = $1
  end
  if v.nil?
    $:.each do |path|
      if path =~ /\/lastversion-([\w\.\-]+)/
        v = $1
        break
      end
    end
  end
  if v.nil?
    path = File.expand_path('../../../.git', __FILE__)
    if File.exists?(path)
      v = Driver::Git.last_version_tag
    end
  end
  if v.nil?
    VERSION = "0.0.0"
  else
    v.sub!(/^v/, '')
    v.sub!(/\+$/, '')
    VERSION = v
  end
end
