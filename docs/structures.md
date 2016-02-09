# Structures

A structure is a blueprint outlining out an object can be converted into a hash
for output in your API.

Say, for example, you have a User object and you wish to present this over your
API. You would find your user and then pass this through your `user` structure
which will return an appropriate hash based on the context the structure is
being called from and your authenticated object.

## Creating a structure

Structures should be placed into your `structures` directory and best practice
dictates they should simply be named `object_structure.rb`, for example a user structure
would be named `user_structure.rb`.

```ruby
structure :user do

  basic :id, :type => Integer, :example => 1234
  basic :username, :type => String, :example => "adam"

  full :full_name, :type => String, :example => "Adam"
  full :last_name, :type => String, :example => "Cooke"
  full :age, :type => Integer, :example => 27
  full :created_at, :type => String, :example => "2014-07-01T11:32:59+01:00"
  full :updated_at, :type => String, :example => "2014-07-01T11:32:59+01:00"

end
```

This example is the most basic way of defining a structure. You see we have defined
a number of attributes which should be included in our structure. Basic attributes are
always included in the structure whereas full attributes are only included when requested.

The basic attributes from a structure is often used on its own when referenced
from other structures. For example, if users had many projects, the project
structure may reference user but only request the basic information as any further
information is not needed.

The full attributes would be returned when listing a specific user or a list
of users on their own. For example, your users/list or users/info methods would
likely return full information rather than just the basic.

Note that when full information is requested, it is always combined with the
information from basic so there's no need to duplicate attribute definitions.

### Mapping

Any attributes which you add to your structure are mapped one to one with the attributes
available on the source object. If the name doesn't match, you can use the `:name`
option to set the actual name of the attribute on the source object.

```ruby
basic :user_id, :source_attribute => :id
```

Alternatively, you can specify a block which will be used when mapping the value to the
correct object.

```ruby
basic :name_in_caps, :value => Proc.new { o.name.upcase }
```

### Grouping

Attributes can be placed into groups which will return a hash containing all items
within the group.

```ruby
group :financials do
  basic :balance, :type => Integer, :example => 12345
  full :last_invoice_raised_at, :type => String, :example => ""
end
```

### Expansions

An expansion allows you to manually define extra information which can be
returned with your user object. For example, in some API methods you may wish
to return extra information about the user's current financial status which
isn't usually returned.

In most cases, an expansion will be a link to another structure which you have
defined. An expansion can be defined as shown below:

```ruby
# A single object which is associated with your user (belongs to)
expansion :currency, :type => Hash, :structure => :currency
# or including an array of objects (has many)
expansion :projects, :type => Array, :structure => :project
```

The same `:structure => :name` can be used on any attribute which you define in your
structure. Therefore, if you need to always include a structure, you can simply
add it to a full or basic line.

### Conditional attributes

You can specify a condition on any attribute or expansion. This can be done by passing
a block to the `:if` option when defining an attribute.

```ruby
condition Proc.new { identity.is_super_special_admin? }, "Only available to special admins" do
  basic :pin
end
```

As well as specifying inline blocks, you can also reference access rules from any
of your authenticators.

```ruby
condition :default => :admins do
  basic :pin
end
```

This will use the `admins` rule on the `default` authenticator to verify whether
or not the `pin` attribute will be displayed.

If you're only using your default authenticator, you can omit the authenticator
name in this call. For example:

```ruby
condition :admins do
  basic :pin
end
```

## Accessing structures from actions

Now... how do you include structures from within an action I hear you ask.
That's actually pretty simple. Throughout both actions and structures, you can
use the `structure` method to load a structure's hash. Here are a number of
examples which you can use to load a hash from a structure.

```ruby
# Return the basic information for a user
structure(:user, user)

# Return the full information for a user
structure(:user, user, :full => true)

# Return the full information plus all expansions
structure(:user, user, :full => true, :expansions => true)

# Return the full information plus specified expansions
structure(:user, user, :full => true, :expansions => [:projects, :financials])

# You don't need to provide the name of the structure if it can
# be auto-determined from the name of the class.
structure(user, :full => true)
```

Remember, these can be used in structures as well as actions. So, you may
want to create expansions which link to other structures. For example, if you
wanted your user hash to include a list of associated projects:

```ruby
expansion :projects do
  o.projects.map { |p| structure(:project, p) }
end
```

If you wish to check whether or not a structure exists before calling it from
an action, you can use the `has_structure_for?` method as shown below.

```ruby
if has_structure_for?(:user)
  structure(:user, user)
else
  error :error, "Structure not found."
end
```

In some cases, you may wish for your consumers to decide which expansions
should be returned. This can be achieved by passing `:paramable` when calling
a `structure` from an action. For example:

```ruby
# Allow consumer to choose from any expansion registered on the structure.
# (taking into account any conditions you specify) and choose whether or not
# to include `full` attributes.
structure(user, :paramable => true)

# Allow the consumer to choose any expansions but not allow control over whether
# full attributes should be returned. Returns all expansions by default.
structure(user, :paramable => {:expansions => true})

# Allow the consumer to choose any expansions but not allow control over whether
# full attributes should be returned. Returns no expansions by default.
structure(user, :paramable => {:expansions => false})

# Allow consumer to choose from any expansions you list. By default, the items
# you list will be included in the response if the user does not request any
# specific expansions.
structure(user, :paramable => {:expansions => [:server, :endpoint]})

# Allow the consumer to control whether or not full attributes should be returned
# in the structure or not but do not allow any control of expansions.
structure(user, :paramable => {:full => true})

# Allow the consumer to control whether or not full attributes should be returned
# but do not return them by default.
structure(user, :paramable => {:full => false})
```

To access these, consumers should send an `_expansions` param with their request which
should contain an array containing the names of the expansions that should be
included. Consumers can also send `true` or `false` in this parameter to return
all or no expansions.

To control access to `full` attributes, consumers should pass `_full` parameter
as true or false.
