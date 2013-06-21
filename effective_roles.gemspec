$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "effective_roles/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "effective_roles"
  s.version     = EffectiveRoles::VERSION
  s.email       = ["matthew@agilestyle.com"]
  s.authors     = ["Matt Riemer"]
  s.homepage    = "http://www.agilestyle.com"
  s.summary     = "Summary of EffectiveRoles."
  s.description = "Description of EffectiveRoles."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails"

  s.add_development_dependency "capybara"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "guard"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "guard-livereload"
  s.add_development_dependency "poltergeist"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "sqlite3"
end
