# Moonrope

Moonrope is an API endpoint library to create RPC-like HTTP JSON APIs in Ruby/Rack applications. 
The primarily goal with this library is provide a simple DSL for defining API controllers, 
actions & structures.

## Defining Objects

To get started, you'll need to create some structures and controllers to use with your API. 
Create a directory and make two folders, one called `structures` and the other called `controllers`.

### Defining a structure

A structure sets out how to turn an object into a hash. Structures are aware of some API environment
information like the version and the authenticated user allowing you to easily tailor the output
based on the visitor.

The best place to look for an example structure is within this repository in the
[test/app/moonrope/structures/user.rb file](https://github.com/viaduct/moonrope/blob/master/test/app/moonrope/structures/user.rb).

### Defining a controller & action

A controller consists of a number of actions which carry out various tasks or return information. 
These actions can then be called whenever needed after verifying access or parameter requirements.

Check the [test/app/moonrope/controllers/users.rb file](https://github.com/viaduct/moonrope/blob/master/test/app/moonrope/controllers/users.rb) for an
exanple of creating a controller.

### Helpers

When you are defining blocks for in your definitions, you can use a number of helper methods as listed 
below.

* `version` - returns the version of the API which has been requested
* `auth` - returns the object which has authenticated this API request
* `globals` - returns a hash of all Moonrope globals
* `error(:not_found, 'Something wasn't found)` - raise a not found error with the provided error
* `set(:variable, 'value')` - sets a variable which can be accessed after the method has been executed. 
  This is used to set `headers` and `flags`.

## Usage

In order to use Moonrope, you'll need to create a directory which contains your controllers
and your structures. To begin, you'll need to create an instance of Moonrope by passing
this directory. You'll probably want to run this when your application starts to that you don't
need to parse files on every request.

```ruby
moonrope = Moonrope::Base.load("path/to/moonrope/dir")
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
```

The result from any of the `execute` method will be an instance of our `ActionResult` class.
It will respond to the following methods:

* `data` - the return value of the `action`
* `status` - the status of the request (success, not-found etc...)
* `headers` - a hash containing HTTP headers which should be returned (defaults to an empty hash)
* `flags` - a set of flags which should be returned
* `time` - the length of time it took to execute the action
