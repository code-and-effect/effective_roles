require "effective_roles/engine"
require "effective_roles/version"

module EffectiveRoles
  mattr_accessor :roles
  mattr_accessor :assignable_roles
  mattr_accessor :role_descriptions

  def self.setup
    yield self
  end

  def self.roles_for_roles_mask(roles_mask)
    roles_mask = Integer(roles_mask)
    EffectiveRoles.roles.reject { |r| (roles_mask & 2**EffectiveRoles.roles.index(r)).zero? }
  end

  def self.roles_collection(obj = nil, user = nil)
    raise ArgumentError.new('EffectiveRoles config.role_descriptions must be a Hash.  The Array syntax is deprecated.') unless EffectiveRoles.role_descriptions.kind_of?(Hash)

    descriptions = role_descriptions[obj.try(:class).to_s] || role_descriptions || {}

    assignable_roles_for(user, obj).map do |role|
      ["#{role}<br>#{descriptions[role]}".html_safe, role]
    end
  end

  def self.assignable_roles_for(user, obj = nil)
    return roles unless user.respond_to?(:is_role_restricted?) # All roles, if the user (or object) is not role_resticted

    assignable = assignable_roles[obj.try(:class).to_s] || assignable_roles || {}

    if assignable.present?
      user.roles.map { |role| assignable[role] }.flatten.compact.uniq
    else
      roles
    end
  end


end
