module EffectiveRoles
  class Engine < ::Rails::Engine
    engine_name 'effective_roles'

    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]

    # Include Helpers to base application
    initializer 'effective_roles.action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        helper EffectiveRolesHelper
      end
    end

    # Include acts_as_addressable concern and allow any ActiveRecord object to call it
    initializer 'effective_roles.active_record' do |app|
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.extend(ActsAsRoleRestricted::ActiveRecord)
      end
    end

    # Set up our default configuration options.
    initializer "effective_roles.defaults", :before => :load_config_initializers do |app|
      eval File.read("#{config.root}/config/effective_roles.rb")
    end

  end
end
