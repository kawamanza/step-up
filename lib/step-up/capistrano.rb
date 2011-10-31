# Capistrano task for step-up.
#
# Just add "require 'step-up/capistrano'" in your Capistrano Capfile:
# 	- A file CURRENT_VERSION will be created after deploy in app root
# 	- A task stepup:deploy_steps will be available.
require 'step-up/deployment'

Capistrano::Configuration.instance(:must_exist).load do
  
  before "deploy:update_code", "stepup:deploy_steps"
  after "deploy:update_code", "stepup:version_file"
  
  Stepup::Deployment.define_task(self, :task, :except => { :no_release => true })
end