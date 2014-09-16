# Effective Roles

Implements multi-role authorization based on an integer roles_mask field

Includes a mixin for adding authentication for any model.

SQL Finders for returning an ActiveRecord::Relation with all permitted records.

Handy formtastic and simple_form helpers for assigning roles.

Rails 3.2.x and Rails 4


## Getting Started

Add to Gemfile:

```ruby
gem 'effective_roles', :git => 'https://github.com/code-and-effect/effective_roles'
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

## Strong Parameters

Make your controller aware of the acts_as_role_restricted passed parameters:

```ruby
def permitted_params
  params.require(:base_object).permit(:roles => [])
end
```


## Behavior

### Defining Roles

All roles are defined in the config/effective_roles.rb initializer.  The roles are defined once and may be applied to any acts_as_role_restricted model in the application.

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

Compare against another acts_as_role_restricted object:

```ruby
user = User.new()
user.roles = []

post = Post.new()
post.roles = [:admin]

user.roles_match_with?(post)
=> false  # User has no roles, but Post requires :admin

post.roles_match_with?(user)
=> true   # Post has the role of :admin, but User requires no roles
```

```ruby
user.roles = [:admin]
post.roles = [:superadmin]

user.roles_match_with?(post)
=> false  # User does not have the superadmin role

post.roles_match_with?(user)
=> false  # Post does not have the admin role
```

```ruby
user.roles = [:superadmin, :admin]
post.roles = [:admin]

user.roles_match_with?(post)
=> true  # User has :admin and so does Post

post.roles_match_with?(user)
=> true  # Post has :admin and so does User
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

When used in a Form Helper (see below), only the appropriate roles will be displayed.

However, this restriction is not enforced on the controller level, so someone could inspect & re-write the form parameters and still assign a role that they are not allowed to.

To prevent this, add something like the following code to your controller:

```ruby
before_filter :only => [:create, :update] do
  if params[:user] && params[:user][:roles]
    params[:user][:roles] = params[:user][:roles] & EffectiveRoles.assignable_roles_for(current_user, User.new()).map(&:to_s)
  end
end
```


## Form Helper

If you pass current_user (or any acts_as_role_restricted object) into these helpers, only the assignable_roles will be displayed.

### Formtastic

```ruby
semantic_form_for @user do |f|
  = effective_roles_fields(f)
```

or

```ruby
semantic_form_for @user do |f|
  = effective_roles_fields(f, current_user)
```

### simple_form

```ruby
simple_form_for @user do |f|
  = f.input :roles, :collection => EffectiveRoles.roles_collection(f.object), :as => :check_boxes
```

or

```ruby
simple_form_for @user do |f|
  = f.input :roles, :collection => EffectiveRoles.roles_collection(f.object, current_user), :as => :check_boxes
```

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
