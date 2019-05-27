module EffectiveRoles
  class Engine < ::Rails::Engine
    engine_name 'effective_roles'

    config.autoload_paths += Dir["#{config.root}/app/models/concerns", "#{config.root}/lib/"]

    # Include acts_as_addressable concern and allow any ActiveRecord object to call it
    initializer 'effective_roles.active_record' do |app|
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.extend(ActsAsRoleRestricted::ActiveRecord)
      end
    end

    # Register the log_page_views concern so that it can be called in ActionController or elsewhere
    initializer 'effective_logging.log_changes_action_controller' do |app|
      Rails.application.config.to_prepare do
        ActiveSupport.on_load :action_controller do
          require 'effective_roles/set_current_user'
          ActionController::Base.include(EffectiveRoles::SetCurrentUser::ActionController)
        end
      end
    end

    # Set up our default configuration options.
    initializer "effective_roles.defaults", :before => :load_config_initializers do |app|
      eval File.read("#{config.root}/config/effective_roles.rb")
    end

  end
end
