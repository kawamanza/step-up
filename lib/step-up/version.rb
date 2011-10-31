module StepUp
  version = nil
  version_file = ::File.expand_path('../../../GEM_VERSION', __FILE__)
  version = File.read(version_file) if ::File.exists?(version_file)
  if version.nil? && ::File.exists?(::File.expand_path('../../../.git', __FILE__))
    version = Driver::Git.new.last_version_tag("HEAD", true) rescue "v0.0.0+0"
    ::File.open(version_file, "w"){ |f| f.write version }
  end
  VERSION = version.gsub(/^v?([^\+]+)\+?\d*$/, '\1')
end
