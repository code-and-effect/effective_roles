# ActsAsRoleRestricted
#
# This model implements the
# https://github.com/ryanb/cancan/wiki/Role-Based-Authorization
# multi role based authorization based on the roles_mask field
#
# Mark your model with 'acts_as_role_restricted'
#
# and create the migration to add the following field:
#
# roles_mask :integer
#

module ActsAsRoleRestricted
  extend ActiveSupport::Concern

  module Base
    def acts_as_role_restricted(multiple: false)
      @acts_as_role_restricted_opts = { multiple: multiple }
      include ::ActsAsRoleRestricted
    end
  end

  included do
    attr_accessor(:current_user) unless respond_to?(:current_user)

    acts_as_role_restricted_options = @acts_as_role_restricted_opts.dup
    self.send(:define_method, :acts_as_role_restricted_options) { acts_as_role_restricted_options }

    validates :roles_mask, numericality: true, allow_nil: true

    validate(if: -> { changes.include?(:roles_mask) && EffectiveRoles.assignable_roles_present?(self) }) do
      roles_was = EffectiveRoles.roles_for(changes[:roles_mask].first)
      changed = (roles + roles_was) - (roles & roles_was)  # XOR

      assignable = EffectiveRoles.assignable_roles_collection(self, current_user) # Returns all roles when user is blank
      unauthorized = changed - assignable

      authorized = roles.dup
      unauthorized.each { |role| authorized.include?(role) ? authorized.delete(role) : authorized.push(role) }

      if unauthorized.present?
        Rails.logger.info "\e[31m unassignable roles: #{unauthorized.map { |role| ":#{role}" }.to_sentence}"
      end

      if unauthorized.present? && current_user.blank? && defined?(Rails::Server)
        self.errors.add(:roles, 'current_user must be present when assigning roles')
      end

      self.roles_mask = EffectiveRoles.roles_mask_for(authorized)
    end

  end

  module ClassMethods
    # Call with for_role(:admin) or for_role(@user.roles) or for_role([:admin, :member]) or for_role(:admin, :member, ...)

    # Returns all records which have been assigned any of the the given roles
    def with_role(*roles)
      where(with_role_sql(roles))
    end

    # Returns all records which have been assigned any of the given roles, as well as any record with no role assigned
    def for_role(*roles)
      sql = with_role_sql(roles) || ''
      sql += ' OR ' if sql.present?
      sql += "(#{self.table_name}.roles_mask = 0) OR (#{self.table_name}.roles_mask IS NULL)"
      where(sql)
    end

    def with_role_sql(*roles)
      roles = roles.flatten.compact
      roles = roles.first.roles if roles.length == 1 && roles.first.respond_to?(:roles)
      roles = (roles.map { |role| role.to_sym } & EffectiveRoles.roles)

      roles.map { |role| "(#{self.table_name}.roles_mask & %d > 0)" % 2**EffectiveRoles.roles.index(role) }.join(' OR ')
    end

    def without_role(*roles)
      roles = roles.flatten.compact
      roles = roles.first.roles if roles.length == 1 && roles.first.respond_to?(:roles)
      roles = (roles.map { |role| role.to_sym } & EffectiveRoles.roles)

      where(
        roles.map { |role| "NOT(#{self.table_name}.roles_mask & %d > 0)" % 2**EffectiveRoles.roles.index(role) }.join(' AND ')
      ).or(where(roles_mask: nil))
    end
  end

  def roles=(roles)
    self.roles_mask = EffectiveRoles.roles_mask_for(roles)
  end

  def roles
    EffectiveRoles.roles_for(roles_mask)
  end

  # if user.is? :admin
  def is?(role)
    roles.include?(role.try(:to_sym))
  end

  # if user.is_any?(:admin, :editor)
  # returns true if user has any role given
  def is_any?(*queried_roles)
    (queried_roles & roles).present?
  end

  # Are both objects unrestricted, or do any roles overlap?
  def roles_overlap?(obj)
    obj_roles = EffectiveRoles.roles_for(obj)
    (roles.blank? && obj_roles.blank?) || (roles & obj_roles).any?
  end

  # Are both objects unrestricted, or are both roles identical?
  def roles_match?(obj)
    obj_roles = EffectiveRoles.roles_for(obj)
    matching_roles = (roles & obj_roles)
    matching_roles.length == roles.length && matching_roles.length == obj_roles.length
  end

  # Any I unrestricted, or do any roles overlap?
  def roles_permit?(obj)
    roles.blank? || roles_overlap?(obj)
  end

  def is_role_restricted?
    roles.present?
  end

end
