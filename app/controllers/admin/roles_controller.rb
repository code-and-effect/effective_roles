module Admin
  class RolesController < ApplicationController
    before_action :authenticate_user!

    layout (EffectiveRoles.config.layout.kind_of?(Hash) ? EffectiveRoles.config.layout[:admin_roles] : EffectiveRoles.config.layout)

    def index
      @page_title = 'Roles'
      EffectiveRoles.authorize!(self, :admin, :effective_roles)
    end
  end
end
