require 'effective_resources'
require 'effective_roles/engine'
require 'effective_roles/version'

module EffectiveRoles

  def self.config_keys
    [:roles, :role_descriptions, :role_colors, :assignable_roles, :layout]
  end

  include EffectiveGem

  def self.permitted_params
    { roles: [] }
  end

  # This method converts whatever is given into its roles
  # Pass an object, Integer, or Symbol to find corresponding role
  def self.roles_for(obj)
    if obj.respond_to?(:is_role_restricted?)
     obj.roles
    elsif obj.kind_of?(Integer)
      roles.reject { |r| (obj & 2 ** config.roles.index(r)).zero? }
    elsif obj.kind_of?(Symbol)
      Array(roles.find { |role| role == obj })
    elsif obj.kind_of?(String)
      Array(roles.find { |role| role == obj.to_sym })
    elsif obj.kind_of?(Array)
      obj.map { |obj| roles_for(obj) }.flatten.compact
    elsif obj.nil?
      []
    else
      raise 'unsupported object passed to EffectiveRoles.roles_for method. Expecting an acts_as_role_restricted object or a roles_mask integer'
    end
  end

  # EffectiveRoles.roles_mask_for(:admin, :member)
  def self.roles_mask_for(*roles)
    roles_for(roles).map { |r| 2 ** config.roles.index(r) }.sum
  end

  def self.color(role)
    raise('expected a role') unless role.kind_of?(Symbol)
    (role_colors || {})[role]
  end

  def self.roles_collection(resource, current_user = nil, only: nil, except: nil, skip_disabled: nil)
    if assignable_roles.present?
      raise('expected object to respond to is_role_restricted?') unless resource.respond_to?(:is_role_restricted?)
      raise('expected current_user to respond to is_role_restricted?') if current_user && !current_user.respond_to?(:is_role_restricted?)
    end

    only = Array(only).compact
    except = Array(except).compact
    skip_disabled = assignable_roles.kind_of?(Hash) if skip_disabled.nil?

    all_roles = assignable_roles_collection(resource)
    assignable = assignable_roles_collection(resource, current_user)

    all_roles.map do |role|
      next if only.present? && !only.include?(role)
      next if except.present? && except.include?(role)

      disabled = !assignable.include?(role)
      next if disabled && skip_disabled

      [
        "#{role}<small class='form-text text-muted'>#{role_description(role, resource)}</small>".html_safe,
        role,
        ({:disabled => :disabled} if disabled)
      ]
    end.compact
  end

  def self.assignable_roles_collection(resource, current_user = nil)
    return roles unless assignable_roles_present?(resource)

    if current_user && !current_user.respond_to?(:is_role_restricted?)
      raise('expected current_user to respond to is_role_restricted?')
    end

    if !resource.respond_to?(:is_role_restricted?)
      raise('expected current_user to respond to is_role_restricted?')
    end

    assigned_roles = if assignable_roles.kind_of?(Hash)
      assignable = (assignable_roles[resource.class.to_s] || assignable_roles || {})
      assigned = [] # our return value

      if current_user.blank?
        assigned = assignable.values.flatten
      end

      if current_user.present?
        assigned = current_user.roles.map { |role| assignable[role] }.flatten.compact
      end

      if assignable[:new_record] && resource.new_record?
        assigned += Array(assignable[:new_record])
      end

      if assignable[:persisted] && resource.persisted?
        assigned += Array(assignable[:persisted])
      end

      assigned
    elsif assignable_roles.kind_of?(Array)
      assignable_roles
    end.uniq

    assigned_roles
  end

  def self.assignable_roles_present?(resource)
    return false unless assignable_roles.present?

    raise 'EffectiveRoles config.assignable_roles_for must be a Hash or Array' unless [Hash, Array].include?(assignable_roles.class)
    raise('expected resource to respond to is_role_restricted?') unless resource.respond_to?(:is_role_restricted?)

    if assignable_roles.kind_of?(Array)
      assignable_roles
    elsif assignable_roles.key?(resource.class.to_s)
      assignable_roles[resource.class.to_s]
    else
      assignable_roles
    end.present?
  end

  private

  def self.role_description(role, obj = nil)
    raise 'EffectiveRoles config.role_descriptions must be a Hash' unless role_descriptions.kind_of?(Hash)

    description = role_descriptions.dig(obj.class.to_s, role) if obj.present?
    description ||= role_descriptions[role]
    description || ''
  end

end
