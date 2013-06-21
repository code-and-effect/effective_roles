EffectiveRoles.setup do |config|
  config.roles = [:superadmin, :admin, :member] # Only add to the end of this array.  Never prepend roles.

  # config.role_descriptions may be an Array or a Hash
  # These role descriptions are just text displayed by the effective_roles_fields() helper

  # Use a Hash if you want different labels depending on the resource being editted
  #

  # config.role_descriptions = {
  #   User => [
  #     "full access to everything. Can manage users and all website content.",
  #     "full access to website content.  Cannot manage users.",
  #     "cannot access admin area.  Can see all content in members-only sections of the website."
  #   ],
  #   Post => [
  #     "allow superadmins to see this post",
  #     "allow admins to see this post",
  #     "allow members to see this post"
  #     ]
  # }

  # Or just keep it simple, and use the same Array of labels for everything
  #
  config.role_descriptions = [
    "full access to everything. Can manage users and all website content.",
    "full access to website content.  Cannot manage users.",
    "cannot access admin area.  Can see all content in members-only sections of the website."
  ]
end
