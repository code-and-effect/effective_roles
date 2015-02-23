EffectiveRoles.setup do |config|
  config.roles = [:superadmin, :admin, :member] # Only add to the end of this array.  Never prepend roles.

  # config.role_descriptions
  # ========================
  # This setting configures the text that is displayed by form helpers (see README.md)
  #
  # Use this Hash syntax if you want different labels depending on the resource being editted
  #
  # config.role_descriptions = {
  #   'User' => {
  #     :superadmin => 'full access to everything. Can manage users and all website content.',
  #     :admin => 'full access to website content.  Cannot manage users.',
  #     :member => 'cannot access admin area.  Can see all content in members-only sections of the website.''
  #   },
  #   'Effective::Page' => {
  #     :superadmin => 'allow superadmins to see this page',
  #     :admin => 'allow admins to see this page',
  #     :member => 'allow members to see this page'
  #   }
  # }
  #
  # Or just keep it simple, and use this Hash syntax of permissions for every resource
  #
  config.role_descriptions = {
    :superadmin => 'full access to everything. Can manage users and all website content.',
    :admin => 'full access to website content.  Cannot manage users.',
    :member => 'cannot access admin area.  Can see all content in members-only sections of the website.'
  }

  # config.assignable_roles
  # Which roles can be assigned by whom
  # =======================
  # When current_user is passed into a form helper function (see README.md)
  # this setting determines which roles that current_user may assign
  #
  # Use this Hash syntax if you want different permissions depending on the resource being editted
  #
  # config.assignable_roles = {
  #   'User' => {
  #     :superadmin => [:superadmin, :admin, :member],  # Superadmins may assign Users any role
  #     :admin => [:admin, :member],                    # Admins may only assign a User the :admin or :member role
  #     :member => []                                   # Members may not assign any roles
  #   },
  #   'Page' => {
  #     :superadmin => [:superadmin, :admin, :member],  # Superadmins may create Pages for any role
  #     :admin => [:admin, :member],                    # Admins may create Pages for admin and members
  #     :member => [:member]                            # Members may create Pages for members
  #   }
  #
  # Or just keep it simple, and use this Hash syntax of permissions for every resource
  #
  config.assignable_roles = {
    :superadmin => [:superadmin, :admin, :member], # Superadmins may assign any resource any role
    :admin => [:admin, :member],                   # Admins may only assign the :admin or :member role
    :member => []                                  # Members may not assign any roles
  }

  # config.disabled_roles
  # Which roles should be displayed as disabled
  # =========================
  # Sometimes you don't want a role to be assignable (see README.md)
  # So that you can overload it yourself and assingn the role programatically
  #
  # Use this Hash syntax if you want different permissions depending on the resource being editted
  #
  # config.disabled_roles = {
  #   'User' => [:member]               # When editing a User object, will be unable to assign the member role
  #   'Page' => [:superadmin, :admin]   # When editing a Page object, will be unable to assign superadmin, admin role
  # }
  #
  # Or just keep it simple, and use this Array syntax of permissions for every resource
  #
  # config.unassignable_roles = [:member]
  config.disabled_roles = {
    'User' => [:member]
  }


end
