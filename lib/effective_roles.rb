require "effective_roles/engine"
require "effective_roles/version"

module EffectiveRoles
  mattr_accessor :roles
  mattr_accessor :role_descriptions

  mattr_accessor :assignable_roles
  mattr_accessor :disabled_roles

  def self.setup
    yield self
  end

  def self.roles_for_roles_mask(roles_mask)
    roles_mask = Integer(roles_mask || 0)
    roles.reject { |r| (roles_mask & 2**roles.index(r)).zero? }
  end

  def self.roles_collection(obj = nil, user = nil)
    assignable_roles_for(user, obj).map do |role|
      [
        "#{role}<p class='help-block'>#{role_description(role, obj)}</p>".html_safe,
        role,
        ({:disabled => :disabled} if disabled_roles_for(obj).include?(role))
      ]
    end
  end

  private

  def self.assignable_roles_for(user, obj = nil)
    raise 'EffectiveRoles config.assignable_roles_for must be a Hash, Array or nil' unless [Hash, Array, NilClass].include?(assignable_roles.class)

    return assignable_roles if assignable_roles.kind_of?(Array)
    return roles if assignable_roles.nil?
    return roles if !user.respond_to?(:is_role_restricted?) # All roles, if the user (or object) is not role_resticted

    assignable = assignable_roles[obj.try(:class).to_s] || assignable_roles || {}

    user.roles.map { |role| assignable[role] }.flatten.compact.uniq
  end

  def self.role_description(role, obj = nil)
    raise 'EffectiveRoles config.role_descriptions must be a Hash' unless role_descriptions.kind_of?(Hash)
    (role_descriptions[obj.try(:class).to_s] || {})[role] || role_descriptions[role] || ''
  end

  def self.disabled_roles_for(obj)
    raise 'EffectiveRoles config.disabled_roles must be a Hash, Array or nil' unless [Hash, Array, NilClass].include?(disabled_roles.class)

    case disabled_roles
    when Array
      disabled_roles
    when Hash
      Array(disabled_roles[obj.try(:class).to_s])
    else
      []
    end
  end

end
