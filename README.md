# Moonrope

Moonrope is an API endpoint library to create RPC-like HTTP JSON APIs in Ruby/Rack applications. 
The primarily goal with this library is provide a simple DSL for defining API controllers, 
methods & structures.

This is still under construction. Doc will follow at some point soon.

## Usage

In order to use Moonrope, you'll need to create a directory which contains your controllers
and your structures. To beign, you'll need to create an instance of Moonrope by passing
this directory. You'll probably want to run this when your application starts to that you don't
need to parse files on every request.

```ruby
moonrope = Moonrope::CoreDSL.load("path/to/moonrope/dir")
```

Once you have this, you can go ahead and call actions or generate structures. 

### Generating a hash from a structure

In the most basic, form you can simply use the `hash` method on a structure and pass it the
source object. The following examples demonstrate some basic functionality.

```ruby
# Get a user to play with
user = User.first

# Find the structure you wish to use
structure = moonrope.structures(:user)

# Generate a hash containing just the basic information
structure.hash(user)                                   

# Generate a hash containing the full information  
structure.hash(user, :full => true)

# Generate a hash containing the full information plus all expansions
structure.hash(user, :full => true, :expansions => true)

# Generate a hash containing the full information plus the animals expansion only
structure.hash(user, :full => true, :expansion => [:animals])
```

If your structure includes a `restriction` block, you will need to ensure you have set
the `auth` global before you call the `hash` method. The following example sets the
`auth` global and then generates the hash.

```ruby
Moonrope.globals(:auth => my_authed_user) do
  structure.hash(user)
end
```

### Calling an API action

Once you have defined an API action, you can go ahead and call it using the examples 
below.

```ruby
# Get the controller
controller = moonrope.controllers(:users)

# Get the action
action = controller.actions[:list]

# Call the action without any parameters
action.execute

# Call the action with some parameters
action.execute(:page => 1, :maximum => 1000)
```

As with structures, these execute calls can be wrapped in a globals block in order to
set the authenticating user. If there is no `auth` global set and you call `check_access`,
the method will always return false.

```ruby
Moonrope.globals(:auth => my_auth_user) do
  if action.check_access
    action.execute
  else
    raise AccessDenied, "Authenticated user does not have access to this action."
  end  
end
```
