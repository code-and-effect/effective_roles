module EffectiveRolesHelper
  # For use in formtastic forms
  def effective_roles_fields(form, options = {})
    if EffectiveRoles.role_descriptions.kind_of?(Hash)
      role_descriptions = EffectiveRoles.role_descriptions[form.object.class.name]
    end
    role_descriptions ||= (EffectiveRoles.role_descriptions || [])

    opts = {:f => form, :role_descriptions => role_descriptions}.merge(options)

    render :partial => 'effective/roles/roles_fields', :locals => opts
  end
end
