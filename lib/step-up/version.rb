module StepUp
  path = File.expand_path('../..', __FILE__)
  v = nil
  if path =~ /\/step-up-([\w\.\-]+)/
    v = $1
  end
  if v.nil?
    $:.each do |path|
      if path =~ /\/step-up-([\w\.\-]+)/
        v = $1
        break
      end
    end
  end
  if v.nil?
    path = File.expand_path('../../../.git', __FILE__)
    if File.exists?(path)
      v = Driver::Git.last_version
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
