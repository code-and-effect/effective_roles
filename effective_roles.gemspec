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
  s.summary     = "Assign multiple roles to any User or other ActiveRecord object. Select only the appropriate objects based on intelligent, chainable ActiveRecord::Relation finder methods."
  s.description = "Assign multiple roles to any User or other ActiveRecord object. Select only the appropriate objects based on intelligent, chainable ActiveRecord::Relation finder methods."
  s.licenses    = ['MIT']

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", [">= 3.2.0"]

  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "sqlite3"

  s.add_development_dependency "guard"
  s.add_development_dependency "guard-rspec"

  s.add_development_dependency "pry"
  s.add_development_dependency "pry-stack_explorer"
  s.add_development_dependency "pry-byebug"

end
