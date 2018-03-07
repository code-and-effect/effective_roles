module Admin
  class RolesController < ApplicationController
    before_action :authenticate_user!

    layout (EffectiveRoles.layout.kind_of?(Hash) ? EffectiveRoles.layout[:admin_roles] : EffectiveRoles.layout)

    def index
      @page_title = 'Roles'
      EffectiveRoles.authorize!(self, :admin, :effective_roles)
    end
  end
end
