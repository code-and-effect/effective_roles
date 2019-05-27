module EffectiveRoles
  module SetCurrentUser
    module ActionController

      # Add me to your ApplicationController
      # before_action :set_effective_roles_current_user

      def set_effective_roles_current_user
        EffectiveRoles.current_user = current_user
      end

    end
  end
end

