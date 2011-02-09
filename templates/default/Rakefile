namespace :stepup do
  desc "Generates file with the latest version of the application"
  task :version_file do
    require 'step-up'
    puts "Generating the version file {{version_file}} with the latest version of the application"
    File.open('{{version_file}}', 'w') { |f| f.write StepUp::Driver::Git.new.last_version_tag("HEAD", true) }
  end
end
