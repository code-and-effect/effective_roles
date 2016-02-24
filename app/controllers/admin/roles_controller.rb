module Admin
  class RolesController < ApplicationController
    before_filter :authenticate_user!   # This is devise, ensure we're logged in.

    layout (EffectiveRoles.layout.kind_of?(Hash) ? EffectiveRoles.layout[:admin_roles] : EffectiveRoles.layout)

    def index
      @page_title = 'Roles'

      EffectiveOrders.authorized?(self, :admin, :effective_roles)
    end
  end
end
