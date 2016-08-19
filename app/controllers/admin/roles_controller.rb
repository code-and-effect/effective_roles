module Admin
  class RolesController < ApplicationController
    respond_to?(:before_action) ? before_action(:authenticate_user!) : before_filter(:authenticate_user!) # Devise

    layout (EffectiveRoles.layout.kind_of?(Hash) ? EffectiveRoles.layout[:admin_roles] : EffectiveRoles.layout)

    def index
      @page_title = 'Roles'

      EffectiveOrders.authorized?(self, :admin, :effective_roles)
    end
  end
end
