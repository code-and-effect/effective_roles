module EffectiveRoles
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc 'Creates an EffectiveRoles initializer in your application.'

      source_root File.expand_path('../../templates', __FILE__)

      def copy_initializer
        template ('../' * 3) + 'config/effective_roles.rb', 'config/initializers/effective_roles.rb'
      end
    end
  end
end
