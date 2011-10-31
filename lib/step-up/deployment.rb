module Stepup
  class Deployment
    def self.define_task(context, task_method = :task, opts = {})
      if defined?(Capistrano) && context.is_a?(Capistrano::Configuration)
        context_name = "capistrano"
        role_default = "{:except => {:no_release => true}}"
      else
        context_name = "vlad"
        role_default = "[:app]"
      end

      context.send :namespace, :stepup do
        send :desc, <<-DESC
          Generates file CURRENT_VERSION with the current version of the application
        DESC
        send task_method, :version_file, opts do
          info "Generating CURRENT_VERSION file..."
          run "cd #{context.fetch(:release_path)}; stepup > CURRENT_VERSION"
        end

        send :desc, <<-DESC
          Show all steps required for deployment
        DESC
        send task_method, :deploy_steps, opts do
          # Get the current version from remote
          run("cat #{context.fetch(:current_release)}/CURRENT_VERSION") do |channel, stream, data|
            set :current_version_from_remote, data.chomp
          end

          version_to_deploy = get_version_to_deploy(context)
          current_version_from_remote = context[:current_version_from_remote]

          if version_to_deploy
            if current_version_from_remote
              info "You are about to deploy #{version_to_deploy} version in replace to current #{current_version_from_remote}"

              info "Please wait while I'm looking for required steps to deploy..."

              deploy_sections = get_deploy_sections(context)
              notes = run_locally("stepup notes --after=#{current_version_from_remote} --upto=#{version_to_deploy} --sections=#{deploy_sections}")

              print_text notes

              important "Please be sure to review all the steps above before proceeding with the deployment!"
            else
              error("Can not find version from remote, so it's impossible to show deploy steps")
            end
          else
            error("Can not find version for deployment. Please, set TAG variable. Example:\n\t  TAG=v1.0.0 cap <env> stepup:deploy_steps")
          end          
        end

        def get_version_to_deploy(context)
          context.fetch(:branch, false) || ENV['TAG']
        end
        
        def get_deploy_sections(context)
          deploy_sections = context.fetch(:deploy_sections, false) || ['deploy_steps']
          deploy_sections.join(' ')
        end

        def print_text(text)
          if colorize?
            puts text
          else
            logger.info(text)
          end
        end

        def info(message)
          if colorize?
            puts "\033[0;32m=> [step-up] #{message}\033[0m"
          else
            logger.info("[step-up] #{message}")
          end
        end

        def important(message)
          if colorize?
            puts "\033[0;33m=> [step-up] #{message}\033[0m"
          else
            logger.important("[step-up] #{message}")
          end
        end

        def error(message)
          if colorize?
            puts "\033[0;31m=> [step-up] #{message}\033[0m"
          else
            logger.error("[step-up] #{message}")
          end
        end

        def colorize?
          $stdout.tty?  
        end
      end
    end
  end
end