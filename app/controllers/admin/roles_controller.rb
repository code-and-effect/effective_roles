module Admin
  class RolesController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_roles) }

    include Effective::CrudController

    if (config = EffectiveRoles.layout)
      layout(config.kind_of?(Hash) ? config[:admin] : config)
    end

    def index
      @page_title = 'Roles'
    end

  end
end
