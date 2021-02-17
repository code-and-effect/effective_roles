$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'effective_roles/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'effective_roles'
  s.version     = EffectiveRoles::VERSION
  s.email       = ['info@codeandeffect.com']
  s.authors     = ['Code and Effect']
  s.homepage    = 'https://github.com/code-and-effect/effective_roles'
  s.summary     = 'Assign multiple roles to any User or other ActiveRecord object. Select only the appropriate objects based on intelligent, chainable ActiveRecord::Relation finder methods.'
  s.description = 'Assign multiple roles to any User or other ActiveRecord object. Select only the appropriate objects based on intelligent, chainable ActiveRecord::Relation finder methods.'
  s.licenses    = ['MIT']

  s.files = Dir['{app,config,db,lib}/**/*'] + ['MIT-LICENSE', 'README.md']

  s.add_dependency 'rails', '>= 3.2.0'
  s.add_dependency 'effective_resources'

end
