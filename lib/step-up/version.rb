module StepUp
  version = nil
  version = $1 if ::File.expand_path('../..', __FILE__) =~ /\/step-up-([\w\.\-]+)/
  version = Driver::Git.last_version if version.nil? && ::File.exists?(::File.expand_path('../../../.git', __FILE__))
  version = "0.0.0" if version.nil?
  VERSION = version.gsub(/^v?([^\+]+)\+?\d*$/, '\1')
end
