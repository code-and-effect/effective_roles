module EffectiveRolesHelper
  # For use in formtastic forms
  def effective_roles_fields(form, user = nil, options = {})
    raise ArgumentError.new('EffectiveRoles config.role_descriptions must be a Hash.  The Array syntax is deprecated.') unless EffectiveRoles.role_descriptions.kind_of?(Hash)

    roles = EffectiveRoles.assignable_roles_for(user, form.object)
    descriptions = EffectiveRoles.role_descriptions[form.object.class.name] || EffectiveRoles.role_descriptions || {}

    opts = {:f => form, :roles => roles, :descriptions => descriptions}.merge(options)

    render :partial => 'effective/roles/roles_fields', :locals => opts
  end
end
