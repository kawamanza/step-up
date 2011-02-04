# created by StepUp
module Version
  def self.to_s
    unless defined? @version
      txt = File.expand_path File.join(__FILE__, '..', '..', '{{version_file}}')
      if File.exists?(txt)
        @version = File.read(txt).chomp
      else
        @version = "{{version_blank}}+"
      end
    end
    @version
  end
end

