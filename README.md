# Effective Roles

Implements multi-role authorization based on an integer roles_mask field

Includes a mixin for adding authentication for any model.

SQL Finders for returning a Relation with all permitted records.

Handy formtastic helper for assigning roles.

Intended for use with the other effective_* gems

Designed to work on its own, or with simple pass through to CanCan

Rails 3.2.x and Rails 4


## Getting Started

Add to Gemfile:

```ruby
gem 'effective_roles'
```

Run the bundle command to install it:

```console
bundle install
```

Install the configuration file:

```console
rails generate effective_roles:install
```

The generator will install an initializer which describes all configuration options.

## Usage

Add the mixin to an existing model:

```ruby
class Post
  acts_as_role_restricted
end
```

Then create a migration to add the :roles_Mask column to the model.

```console
rails generate migration add_roles_to_post roles_mask:integer
```

which will create a migration something like

```ruby
class AddRolesToPost < ActiveRecord::Migration
  def change
    add_column :posts, :roles_mask, :integer
  end
end
```

## Behavior

### Defining Roles

All roles are defined in the config/effective_roles.rb initializer.

### Model

Assign roles:

```ruby
post.roles = [:admin, :superamdin]
post.save
```

See if an object has been assigned a specific role:

```ruby
post.is_role_restricted?
=> true

post.is?(:admin)
=> true

post.roles
=> [:admin, :superadmin]
```

### Finder Methods

Find all objects that have been assigned a specific role (or roles).  Will not return posts that have no assigned roles (roles_mask = 0)

```ruby
Post.with_role(:admin, :superadmin)   # Can pass as an array if you want
```

Find all objects that are appropriate for a specific role.  Will return posts that have no assigned roles

```ruby
Post.for_role(:admin)
Post.for_role(current_user.roles)
```

These are both ActiveRecord::Relations, so you can chain them with other methods like normal.

## Form Helper

### Formtastic

```ruby
semantic_form_for @user do |f|
  = effective_roles_fields(f)
```

### simple_form

```ruby
simple_form_for @user do |f|
  = f.input :roles, :collection => EffectiveRoles.roles_collection(f.object), :as => :check_boxes 
```

## License

MIT License.  Copyright Code and Effect Inc. http://www.codeandeffect.com

You are not granted rights or licenses to the trademarks of Code and Effect

## Credits

This model implements the https://github.com/ryanb/cancan/wiki/Role-Based-Authorization multi role based authorization based on the roles_mask field

### Testing

The test suite for this gem is unfortunately not yet complete.

Run tests by:

```ruby
rake spec
```
