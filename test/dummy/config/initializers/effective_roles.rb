EffectiveRoles.setup do |config|
  config.roles = [:superadmin, :admin, :member] # Only add to the end of this array. Never prepend roles.

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

  # config.role_colors
  # ========================
  # Assign a bootstrap color to a role. Optional.
  # Used by the roles_badges() helper to display this role as a badge
  config.role_colors = { superadmin: :primary, admin: :secondary }

  # config.assignable_roles
  # Which roles can be assigned by whom
  # =======================
  # When current_user is passed into a form helper function (see README.md)
  # this setting determines which roles that current_user may assign
  #
  # you must assign current_user to all acts_as_role_restricted resources when saving changes to the roles or roles_mask.
  #
  # You should probably do this in your controller by one of the following methods:
  # 1.) Setting resource.current_user = current_user directly.
  # 2.) Using before_action :set_effective_roles_current_user
  # 3.) Using Effective::CrudController does this automatically.
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
  #   },
  #   'Post' => false                                   # Don't enforce assignable roles validation
  #   }
  #
  # Or just keep it simple, and use this Hash syntax of permissions for every resource
  #
  # config.assignable_roles = {
  #   :superadmin => [:superadmin, :admin, :member], # Superadmins may assign any resource any role
  #   :admin => [:admin, :member],                   # Admins may only assign the :admin or :member role
  #   :member => [],                                 # Members may not assign any roles
  #   :new_record => [:member]                       # Member may be assigned to a new_record without a current_user
  # }

  # Authorization Method
  # This gem serves an /admin/roles endpoint that calls EffectiveResources.authorize!

  # Layout Settings
  # config.layout = 'admin'
end
