module StepUp
  version = nil
  version = $1 if ::File.expand_path('../..', __FILE__) =~ /\/step-up-([\w\.\-]+)/
  version = "0.0.0" if version.nil?
  version = Driver::Git.new.last_version_tag if version.nil? && ::File.exists?(::File.expand_path('../../../.git', __FILE__))
  VERSION = version.gsub(/^v?([^\+]+)\+?\d*$/, '\1')
end
