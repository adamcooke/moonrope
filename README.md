# Moonrope

Moonrope is an API endpoint library to create RPC-like HTTP JSON APIs in Ruby/Rack applications. 
The primarily goal with this library is provide a simple DSL for defining API controllers, 
actions & structures.

## Defining Objects

In order to use Moonrope, you need to define your API controllers, structure & other
configuration. The best way to learn this is to look at the examples in the examples 
directory of this repository.

## Usage

To begin, you'll need to create an instance of Moonrope by passing your configuration directory. You'll probably want to run this when your application starts so that you don't
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
# Get the action
action = moonrope / :users / :list

# Execute the action
result = action.execute

# Look at the result
result.status   #=> Status of the request
result.data     #=> The return value of the action
result.flags    #=> Any flags set in the action
result.headers  #=> Any headers set in the action
result.time     #=> The time taken to run the request
```
