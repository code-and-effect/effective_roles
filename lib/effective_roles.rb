require 'effective_roles/engine'
require 'effective_roles/version'

module EffectiveRoles
  mattr_accessor :roles
  mattr_accessor :role_descriptions

  mattr_accessor :layout

  mattr_accessor :assignable_roles
  mattr_accessor :disabled_roles

  mattr_accessor :authorization_method

  def self.setup
    yield self
  end

  def self.permitted_params
    {roles: []}
  end

  def self.authorized?(controller, action, resource)
    if authorization_method.respond_to?(:call) || authorization_method.kind_of?(Symbol)
      raise Effective::AccessDenied.new() unless (controller || self).instance_exec(controller, action, resource, &authorization_method)
    end
    true
  end

  # This method converts whatever is given into its roles
  # Pass an object, Integer, or Symbol to find corresponding role
  def self.roles_for(obj)
    if obj.respond_to?(:is_role_restricted?)
     obj.roles
    elsif obj.kind_of?(Integer)
      roles.reject { |r| (obj & 2**roles.index(r)).zero? }
    elsif obj.kind_of?(Symbol)
      [roles.find { |role| role == obj }].compact
    elsif obj.nil?
      []
    else
      raise 'unsupported object passed to EffectiveRoles.roles_for method.  Expecting an acts_as_role_restricted object or a roles_mask integer'
    end
  end

  # EffectiveRoles.roles_mask_for(:admin, :member)
  def self.roles_mask_for(*roles)
    (Array(roles).flatten.map(&:to_sym) & EffectiveRoles.roles).map { |r| 2**EffectiveRoles.roles.index(r) }.sum
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

  def self.assignable_roles_for(user, obj = nil)
    raise 'EffectiveRoles config.assignable_roles_for must be a Hash, Array or nil' unless [Hash, Array, NilClass].include?(assignable_roles.class)

    return assignable_roles if assignable_roles.kind_of?(Array)
    return roles if assignable_roles.nil?
    return roles if !user.respond_to?(:is_role_restricted?) # All roles, if the user (or object) is not role_resticted

    assignable = assignable_roles[obj.try(:class).to_s] || assignable_roles || {}

    user.roles.map { |role| assignable[role] }.flatten.compact.uniq
  end

  # This is used by the effective_roles_summary_table helper method
  def self.authorization_level(controller, role, resource)
    return :unknown unless (authorization_method.respond_to?(:call) || authorization_method.kind_of?(Symbol))
    return :unknown unless (controller.current_user rescue nil).respond_to?(:roles=)

    # Store the current ability (cancan support) and roles
    current_ability = controller.instance_variable_get(:@current_ability)
    current_user = controller.instance_variable_get(:@current_user)
    current_user_roles = controller.current_user.roles

    # Set up the user, so the check is done with the desired permission level
    controller.instance_variable_set(:@current_ability, nil)

    level = nil

    case role
    when :signed_in
      controller.current_user.roles = []
    when :public
      controller.instance_variable_set(:@current_user, nil)

      if defined?(EffectiveLogging) && EffectiveLogging.respond_to?(:supressed?)
        EffectiveLogging.supressed { (controller.request.env['warden'].set_user(false) rescue nil) }
      else
        (controller.request.env['warden'].set_user(false) rescue nil)
      end
    else
      controller.current_user.roles = [role]
    end

    # Find the actual authorization level
    level = _authorization_level(controller, role, resource, authorization_method)

    # Restore the existing current_user stuff
    if role == :public
      ActiveRecord::Base.transaction do
        if defined?(EffectiveLogging) && EffectiveLogging.respond_to?(:supressed?)
          EffectiveLogging.supressed { (controller.request.env['warden'].set_user(current_user) rescue nil) }
        else
          (controller.request.env['warden'].set_user(current_user) rescue nil)
        end

        raise ActiveRecord::Rollback
      end
    end

    controller.instance_variable_set(:@current_ability, current_ability)
    controller.instance_variable_set(:@current_user, current_user)
    controller.current_user.roles = current_user_roles

    level
  end

  private

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

  def self._authorization_level(controller, role, resource, auth_method)
    resource = (resource.new() rescue resource) if resource.kind_of?(ActiveRecord::Base)

    # Custom actions
    if resource.kind_of?(Hash)
      resource.each do |key, value|
        return (controller.instance_exec(controller, key, value, &auth_method) rescue false) ? :yes : :no
      end
    end

    # Check for Manage
    return :manage if (
      (controller.instance_exec(controller, :create, resource, &auth_method) rescue false) &&
      (controller.instance_exec(controller, :update, resource, &auth_method) rescue false) &&
      (controller.instance_exec(controller, :show, resource, &auth_method) rescue false) &&
      (controller.instance_exec(controller, :destroy, resource, &auth_method) rescue false)
    )

    # Check for Update
    return :update if (controller.instance_exec(controller, :update, resource, &auth_method) rescue false)

    # Check for Update Own
    if resource.respond_to?('user=')
      resource.user = controller.current_user
      return :update_own if (controller.instance_exec(controller, :update, resource, &auth_method) rescue false)
      resource.user = nil
    elsif resource.respond_to?('user_id=')
      resource.user_id = controller.current_user.id
      return :update_own if (controller.instance_exec(controller, :update, resource, &auth_method) rescue false)
      resource.user_id = nil
    elsif resource.kind_of?(User)
      return :update_own if (controller.instance_exec(controller, :update, controller.current_user, &auth_method) rescue false)
    end

    # Check for Create
    return :create if (controller.instance_exec(controller, :create, resource, &auth_method) rescue false)

    # Check for Show
    return :show if (controller.instance_exec(controller, :show, resource, &auth_method) rescue false)

    # Check for Index
    return :index if (controller.instance_exec(controller, :index, resource, &auth_method) rescue false)

    # Check for Destroy
    return :destroy if (controller.instance_exec(controller, :destroy, resource, &auth_method) rescue false)

    :none
  end

end
