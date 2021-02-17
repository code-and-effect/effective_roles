require 'effective_roles/engine'
require 'effective_roles/version'

module EffectiveRoles
  # mattr_accessor :roles
  # mattr_accessor :role_descriptions
  # mattr_accessor :assignable_roles

  # mattr_accessor :layout
  # mattr_accessor :authorization_method

  def self.config(namespace = nil)
    @config ||= ActiveSupport::OrderedOptions.new
    namespace ||= Tenant.current if defined?(Tenant)

    if namespace
      @config[namespace] ||= ActiveSupport::OrderedOptions.new
    else
      @config
    end
  end

  def self.setup(namespace = nil, &block)
    yield(config(namespace))
  end

  def self.permitted_params
    { roles: [] }
  end

  def self.authorized?(controller, action, resource)
    @_exceptions ||= [Effective::AccessDenied, (CanCan::AccessDenied if defined?(CanCan)), (Pundit::NotAuthorizedError if defined?(Pundit))].compact

    return !!authorization_method unless authorization_method.respond_to?(:call)
    controller = controller.controller if controller.respond_to?(:controller)

    begin
      !!(controller || self).instance_exec((controller || self), action, resource, &authorization_method)
    rescue *@_exceptions
      false
    end
  end

  def self.authorize!(controller, action, resource)
    raise Effective::AccessDenied unless authorized?(controller, action, resource)
  end

  # This is set by the "set_effective_roles_current_user" before_filter.
  def self.current_user=(user)
    @effective_roles_current_user = user
  end

  def self.current_user
    @effective_roles_current_user
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
    elsif obj.kind_of?(String)
      [roles.find { |role| role == obj.to_sym }].compact
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
    roles_for(roles).map { |r| 2**EffectiveRoles.roles.index(r) }.sum
  end

  def self.roles_collection(resource, current_user = nil, only: nil, except: nil, multiple: nil)
    if assignable_roles.present?
      raise('expected object to respond to is_role_restricted?') unless resource.respond_to?(:is_role_restricted?)
      raise('expected current_user to respond to is_role_restricted?') if current_user && !current_user.respond_to?(:is_role_restricted?)
    end

    only = Array(only).compact
    except = Array(except).compact
    multiple = resource.acts_as_role_restricted_options[:multiple] if multiple.nil?
    assignable = assignable_roles_collection(resource, current_user, multiple: multiple)

    roles.map do |role|
      next if only.present? && !only.include?(role)
      next if except.present? && except.include?(role)

      [
        "#{role}<p class='help-block text-muted'>#{role_description(role, resource)}</p>".html_safe,
        role,
        ({:disabled => :disabled} unless assignable.include?(role))
      ]
    end.compact
  end

  def self.assignable_roles_collection(resource, current_user = nil, multiple: nil)
    return roles unless assignable_roles_present?(resource)

    current_user ||= (EffectiveRoles.current_user || (EffectiveLogging.current_user if defined?(EffectiveLogging)))

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

    # Check boxes
    multiple = resource.acts_as_role_restricted_options[:multiple] if multiple.nil?
    return assigned_roles if multiple

    # Radios
    (resource.roles - assigned_roles).present? ? [] : assigned_roles
  end

  def self.assignable_roles_present?(resource)
    return false if assignable_roles.nil?

    raise 'EffectiveRoles config.assignable_roles_for must be a Hash, Array or nil' unless [Hash, Array].include?(assignable_roles.class)
    raise('expected resource to respond to is_role_restricted?') unless resource.respond_to?(:is_role_restricted?)

    return assignable_roles.present? if assignable_roles.kind_of?(Array)

    if assignable_roles.kind_of?(Array)
      assignable_roles
    elsif assignable_roles.key?(resource.class.to_s)
      assignable_roles[resource.class.to_s]
    else
      assignable_roles
    end.present?
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

      if defined?(EffectiveLogging)
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
        if defined?(EffectiveLogging)
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
