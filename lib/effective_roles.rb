require "effective_roles/engine"
require "effective_roles/version"

module EffectiveRoles
  mattr_accessor :roles
  mattr_accessor :role_descriptions

  def self.setup
    yield self
  end

end
