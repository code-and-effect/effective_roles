require "effective_roles/engine"
require "effective_roles/version"

module EffectiveRoles
  mattr_accessor :roles
  mattr_accessor :role_descriptions

  def self.setup
    yield self
  end

  def self.roles_collection(obj = nil)
    descriptions = if role_descriptions.kind_of?(Hash)
      role_descriptions[obj.try(:class).to_s] || role_descriptions.first[1]
    else
      role_descriptions
    end

    roles.each_with_index.map do |role, index|
      ["#{role}<br>#{descriptions[index]}".html_safe, role]
    end

  end
end
