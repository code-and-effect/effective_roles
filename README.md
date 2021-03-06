# Effective Roles

Assign multiple roles to any User or other ActiveRecord object. Select only the appropriate objects based on intelligent, chainable ActiveRecord::Relation finder methods.

Implements multi-role authorization based on an integer roles_mask field

Includes a mixin for adding authentication for any model.

SQL Finders for returning an ActiveRecord::Relation with all permitted records.


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
  acts_as_role_restricted                  # Singular role, use radio buttons
  acts_as_role_restricted multiple: true   # Multiple roles. use check boxes
end
```

Then create a migration to add the :roles_mask column to the model.

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

## Usage

### Defining Roles

All roles are defined in the config/effective_roles.rb initializer.  The roles are defined once and may be applied to any acts_as_role_restricted model in the application.

### Model

Assign roles:

```ruby
post.roles = [:admin, :superadmin]
post.save
```

See if an object has been assigned a specific role:

```ruby
post.is_role_restricted?
=> true

post.is?(:admin)
=> true

post.is_any?(:editor, :superadmin)
=> true

post.roles
=> [:admin, :superadmin]
```

Compare against another acts_as_role_restricted object:

```ruby
post = Post.new()
post.roles = :admin

user = User.new()
user.roles = nil

post.roles_permit?(user)
=> false  # Post requires the :admin role, but User has no admin role
```

```ruby
post.roles = :superadmin
user.roles = :admin

post.roles_permit?(user)
=> false  # User does not have the superadmin role
```

```ruby
post.roles = :admin
user.roles = [:superadmin, :admin]

post.roles_permit?(user)
=> true  # User has required :admin role
```

### Finder Methods

Find all objects that have been assigned a specific role (or roles).  Will not return posts that have no assigned roles (roles_mask = 0 or NULL)

```ruby
Post.with_role(:admin, :superadmin)   # Can pass as an array if you want
Post.with_role(current_user.roles)
```

Find all objects that are appropriate for a specific role.  Will return posts that have no assigned roles

```ruby
Post.for_role(:admin)
Post.for_role(current_user.roles)
```

These are both ActiveRecord::Relations, so you can chain them with other methods like normal.

## Assignable Roles

Specifies which roles can be assigned to a resource by a specific user.

See the initializers/effective_roles.rb for more information.

```ruby
  config.assignable_roles = {
    :superadmin => [:superadmin, :admin, :member], # Superadmins may assign any resource any role
    :admin => [:admin, :member],                   # Admins may only assign the :admin or :member role
    :member => []                                  # Members may not assign any roles
  }
```

When using assignable roles, you must assign the acts_as_role_restricted resource a `current_user` when saving changes to the roles or roles mask:

You can do this in one of three ways:

1. Setting resource.current_user = current_user in your controller update action directly.
2. Add `before_action -> { @thing.current_user = current_user }` to your ApplicationController
3. Using `Effective::CrudController` to do this automatically.

This restriction is only applied when running within the rails server. Not on rails console or db:seeds.

## Form Helper

If you pass current_user (or any acts_as_role_restricted object) into these helpers, only the assignable_roles will be displayed.

### effective_form_with

Depending on your `acts_as_role_restricted multiple: ` value:

```ruby
effective_form_with(model: @user) do |f|
  = f.checks :roles, EffectiveRoles.roles_collection(f.object, current_user)
```

```ruby
effective_form_with(model: @user) do |f|
  = f.radios :roles, EffectiveRoles.roles_collection(f.object, current_user)
```

### simple_form

```ruby
simple_form_for @user do |f|
  = f.input :roles, collection: EffectiveRoles.roles_collection(f.object, current_user), as: :check_boxes
```

```ruby
simple_form_for @user do |f|
  = f.input :roles, collection: EffectiveRoles.roles_collection(f.object, current_user), as: :radio_buttons
```

### Strong Parameters

Make your controller aware of the passed parameters:

```ruby
def permitted_params
  params.require(:base_object).permit(EffectiveRoles.permitted_params)
end
```

The actual permitted parameters are:

```ruby
roles: []
```

## Summary

Use the `effective_roles_summary` view helper to output a list of roles and descriptions.

```ruby
effective_roles_summary(user) # any acts_as_role_restricted object
effective_roles_summary(post)
```


## Summary table

Use the `effective_roles_summary_table` view helper to output a table of the actual permission levels for each role and ActiveRecord object combination.

You can customize the helper function with the following keys: roles, only, except, plus and additionally

```ruby
effective_roles_summary_table(roles: [:admin, :superadmin], only: [Post, Event])
effective_roles_summary_table(except: [Post, User])
effective_roles_summary_table(plus: [Reports::PostReport]) # Add a non ActiveRecord object to the output, sorted with the other model names
effective_roles_summary_table(additionally: [Reports::PostReport]) # Add a non ActiveRecord object to the output, after the other models
effective_roles_summary_table(plus: {post_report: :export}) # A custom permission based on a symbol
```

You can override the `effective_roles_authorization_label(klass)` method for better control of the label display.

## Bitmask Implementation

The underlying role information for any acts_as_role_restricted ActiveRecord object is stored in that object's roles_mask field.

roles_mask is an integer, in which each power of 2 represents the presence or absense of a role.

If we have the following roles defined:

```ruby
EffectiveRoles.setup do |config|
  config.roles = [:superadmin, :admin, :betauser, :member]
end
```

Then the following will hold true:

```ruby
user = User.new()

user.roles
=> []

user.roles_mask
=> 0

user.roles = [:superadmin]
user.roles_mask
=> 1

user.roles = [:admin]
user.roles_mask
=> 2

user.roles = [:betauser]
user.roles_mask
=> 4

user.roles = [:member]
user.roles_mask
=> 8
```

As well:

```ruby
user.roles = [:superadmin, :admin]
user.roles_mask
=> 3

user.roles = [:superadmin, :betauser]
user.roles_mask
=> 5

user.roles = [:admin, :member]
user.roles_mask
=> 10

user.roles = [:superadmin, :admin, :betauser, :member]
user.roles_mask
=> 15
```

Keep in mind, when using this gem you should never be working directly with the roles_mask field.

All roles are get/set through the roles and roles= methods.


## License

MIT License.  Copyright [Code and Effect Inc.](http://www.codeandeffect.com/)

## Credits

This model implements the https://github.com/ryanb/cancan/wiki/Role-Based-Authorization multi role based authorization based on the roles_mask field

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request
