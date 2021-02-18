module EffectiveRolesHelper
  def effective_roles_summary(obj, options = {}) # User or a Post, any acts_as_roleable
    raise 'expected an acts_as_roleable object' unless obj.respond_to?(:roles)

    descriptions = EffectiveRoles.role_descriptions[obj.class.name] || EffectiveRoles.role_descriptions || {}
    opts = { obj: obj, roles: obj.roles, descriptions: descriptions }.merge(options)

    render partial: 'effective/roles/summary', locals: opts
  end

  # Output a table of permissions for each role based on current permissions

  # effective_roles_summary_table(roles: [:admin, :superadmin], only: [Post, Event])
  # effective_roles_summary_table(except: [Post, User])
  # effective_roles_summary_table(aditionally: [Report::PostReport, User, {clinic_report: :export}])
  def effective_roles_summary_table(opts = {})
    raise 'Expected argument to be a Hash' unless opts.kind_of?(Hash)

    roles = Array(opts[:roles]).presence
    roles ||= [:public, :signed_in] + EffectiveRoles.roles

    if opts[:only].present?
      klasses = Array(opts[:only])
      render partial: '/effective/roles/summary_table', locals: { klasses: klasses, roles: roles }
      return
    end

    # Figure out all klasses (ActiveRecord objects)
    Rails.application.eager_load!
    tables = ActiveRecord::Base.connection.tables - ['schema_migrations', 'delayed_jobs', 'active_storage_attachments']

    klasses = ActiveRecord::Base.descendants.select do |model|
      (model.respond_to?(:table_name) && tables.include?(model.table_name))
    end

    if opts[:except]
      klasses = klasses - Array(opts[:except])
    end

    if opts[:plus]
      klasses = klasses + Array(opts[:plus])
    end

    klasses = klasses.sort do |a, b|
      a = a.respond_to?(:name) ? a.name : a.to_s
      b = b.respond_to?(:name) ? b.name : b.to_s

      a_namespaces = a.split('::')
      b_namespaces = b.split('::')

      if a_namespaces.length != b_namespaces.length
        a_namespaces.length <=> b_namespaces.length
      else
        a <=> b
      end
    end

    if opts[:additionally]
      klasses = klasses + Array(opts[:additionally])
    end

    render partial: '/effective/roles/summary_table', locals: { klasses: klasses, roles: roles }
  end

  def effective_roles_authorization_badge(level)
    label = defined?(EffectiveBootstrap) ? 'badge' : 'label'

    case level
    when :manage
      content_tag(:span, 'Full', class: "#{label} #{label}-primary")
    when :update
      content_tag(:span, 'Edit', class: "#{label} #{label}-success")
    when :update_own
      content_tag(:span, 'Edit Own', class: "#{label} #{label}-info")
    when :create
      content_tag(:span, 'Create', class: "#{label} #{label}-success")
    when :show
      content_tag(:span, 'Read only', class: "#{label} #{label}-warning")
    when :index
      content_tag(:span, 'Read only', class: "#{label} #{label}-warning")
    when :destroy
      content_tag(:span, 'Delete only', class: "#{label} #{label}-warning")
    when :none
      content_tag(:span, 'No Access', class: "#{label} #{label}-danger")
    when :yes
      content_tag(:span, 'Yes', class: "#{label} #{label}-primary")
    when :no
      content_tag(:span, 'No', class: "#{label} #{label}-danger")
    when :unknown
      content_tag(:span, 'Unknown', class: "#{label}")
    else
      content_tag(:span, level.to_s.titleize, class: "#{label} #{label}-info")
    end
  end

  def effective_roles_authorization_label(klass)
    # Custom permissions
    return "#{klass.keys.first} #{klass.values.first}" if klass.kind_of?(Hash) && klass.length == 1

    klass = klass.keys.first if klass.kind_of?(Hash)
    klass.respond_to?(:name) ? klass.name : klass.to_s
  end

  # This is used by the effective_roles_summary_table helper method
  def effective_roles_authorization_level(controller, role, resource)
    authorization_method = EffectiveResources.authorization_method

    raise('expected an authorization method') unless (authorization_method.respond_to?(:call) || authorization_method.kind_of?(Symbol))
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
    level = effective_roles_item_authorization_level(controller, role, resource, authorization_method)

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

  def effective_roles_item_authorization_level(controller, role, resource, auth_method)
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
    elsif resource.class.name.end_with?('User')
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
