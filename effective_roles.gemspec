$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "effective_roles/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "effective_roles"
  s.version     = EffectiveRoles::VERSION
  s.email       = ["info@codeandeffect.com"]
  s.authors     = ["Code and Effect"]
  s.homepage    = "https://github.com/code-and-effect/effective_roles"
  s.summary     = "Implements multi-role authorization based on an integer roles_mask field"
  s.description = "Implements multi-role authorization based on an integer roles_mask field. Includes a mixin for adding authentication for any model. SQL Finders for returning a Relation with all permitted records. Handy formtastic helper for assigning roles. Intended for use with the other effective_* gems Designed to work on its own, or with simple pass through to CanCan"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails"

  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "sqlite3"
end
