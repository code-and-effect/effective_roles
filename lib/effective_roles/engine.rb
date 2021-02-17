module EffectiveRoles
  class Engine < ::Rails::Engine
    engine_name 'effective_roles'

    # Include acts_as_addressable concern and allow any ActiveRecord object to call it
    initializer 'effective_roles.active_record' do |app|
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.extend(ActsAsRoleRestricted::Base)
      end
    end

    # Set up our default configuration options.
    initializer "effective_roles.defaults", :before => :load_config_initializers do |app|
      eval File.read("#{config.root}/config/effective_roles.rb")
    end

  end
end
