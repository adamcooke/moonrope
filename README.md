# Moonrope

Moonrope is an API server & client tool for Ruby/Rack applications. It
provides everything you need to create an API within your application and
have a Ruby API client provided without any development.

This repository is the server-side library which allows you to easily define
your API actions & data structures and serve them out using Rack middleware.

* [Documentation](http://rdoc.info/github/viaduct/moonrope/master/frames)
* [Travis CI](https://travis-ci.org/viaduct/moonrope)

[![Build Status](https://travis-ci.org/adamcooke/moonrope.svg?branch=master)](https://travis-ci.org/adamcooke/moonrope)

## The key components of a Moonrope API

* **Controller** - a controller is a set of actions which can be executed by
  users.

* **Action** - an action is a method which someone can execute on your API. An
  action may return data, update data or destroy data. Every action returns
  some data to a user.

* **Structure** - a structure allows you to convert a Ruby object (in most
  cases this would be an Active Record model) into a hash which can be returned
  to a user.

* **Helper** - a helper is a method which you can define globally or on a
  per controller basis. A helper can execute code & return objects which you
  can use in your actions.

These various components are defined in files which are then loaded by
Moonrope automatically when your application starts. In a Rails application,
by default these should be placed into a `api` directory in the root of
your application. The actual directory structure for your Moonrope API should
look like this:

* `api/controllers` - contains all of your controllers
* `api/structures` - contains all your structures
* `api/helpers` - contains any helpers you have defined

The name of files within these folders is not important. All files ending with
`.rb` are loaded.

## Creating an action

Before you can create an action, you'll need to create a controller which can
contain your action. In this example, we're going to create an action which
will just say "Hello world!".

```ruby
controller :hello do
  action :world do
    description "Say hello world"
    action do
      "Hello world!"
    end
  end
end
```

This is the most basic definition of a controller & action. It specifies the
name of the controller (`hello`) and then adds an action to this controller.
This action has the name `world`, a description and a block which specifies
what you should be executed when this action is run.

### Parameters

It's very common to need to receive additional information when the request
is made. Moonrope allows you to receive parameters into your action like
normal HTTP requests.

To access a paremters within your action (or helper), you can simply access
it using `params[:name_of_parameter]` or `params.name_of_parameter`. For example,
if you wanted to access a parameter named `page` you can use `params[:page]` or
`params.page`. If the value sent is nil or an empty string this will return nil.

#### Defining supported parameters

You can define which parameters are supported for actions. This is an example
action which defines some parameters.

```ruby
action :say_hello do
  description "Say some things to a user"
  param :name, :required => true, :type => String
  param :age, :required => true, :type => Integer
  param :hair_color, :type => String, :default => 'Unknown'
  param :phone_number, :type => String, :regex => /\A\+[\d\s]+\z/
  action do
    "Hello #{params.name}! You are #{params.age} and your hair is #{params.hair_color}!"
  end
end
```

When defining a parameter you can define a number of options to assist with
validation & default population.

* `:required => true` - this will require that this parameter is passed with
  the request. If not an error will be raised before the action is executed.
* `:type => String` - this sets what type of object should be submitted. In
  most cases this should be `String`, `Integer`, `Hash` or `Array`.
* `:default => 'Value here'` - sets the default value for the parameter if
  none is passed.
* `:regex => //` - sets a regex which the passed value must conform to

### Raising errors

If, when you're exectuting an action, you may need to raise an error. For
example, you may have a validation error or an object which was requested
might not be found.

```ruby
action do
  page = Page.find_by_id(params.id)
  if page.nil?
    error :not_found, "Page not found matching ID '#{params.id}'"
  end
end
```

You can use the following options as the first parameter to the `error` method.
Each of these will raise a different type of error.

* `:not_found` - an object hasn't been found
* `:access_denied` - access to a given resource is not permitted
* `:validation_error` - an object cannot be updated with the provided parameters
* `:parameter_error` - a provided parameter is invalid
* You can also pass any other type of error however this will be reported as a
  `error` to the end user plus whatever message you specify.

You can also raise structured errors. These are errors which will always return a
code and a message plus any additional data you want to send. These are the preferred
way of sending errors in Moonrope.

```ruby
action do
  if application.suspended?
    # You can call a structured error directly.
    structured_error 'application-suspended', "The application has been suspended.", :app_name => app.name
    # Also, any call to error which starts with a string will be considered a structured error
    error 'application-suspended', "The application has been suspended.", :app_name => app.name
  end
end
```

These will eb reporting to the user as `error` in the request status. The body will
contain a hash with the `code` and `message` plus any other attributes you specify
when you raise the error.

### Flags

Flags contain extra information which you wish to return with your request
without interrupting the data you are returning. Think of them like HTTP headers.
A use case for these may be that you wish to paginate data and need to return
pagination details along with the actual data.

```ruby
action do
  # Get some pagianted data
  pages = Page.paginate(:page => params.page)
  # Set the flags
  set_flag :current_page, pages.page
  set_flag :items_per_page, pages.items_per_page
  set_flag :total_pages, pages.total_pages
  # Return all the pages as normal
  pages
end
```

### Authentication

Deciding whether or not to permit access to your API is a fundamental part
of any API. The **authenticator** uses information avaiable in the request
and returns an object of the "authenticated object". In many cases this
authenticated object will be an instance of your user class but it can be
anything you decide.

An authenticator is defined at the same level as controllers & structures.
Best practice dictates it should be placed into its own `authenticator.rb`
file.

In this example, we are going to look at the contents of HTTP headers to
get the provided username & password and resolve this to a local User object.
If no user object is found, we will raise an access denied error.

```ruby
authenticator do
  user = User.authenticate(request.headers['X-Auth-Username'], request.headers['X-Auth-Password])
  if user.is_a?(User)
    user
  else
    error :access_denied, "Invalid user credentials provided"
  end
end
```

#### Accessing the authenticated user in actions

In order to access this authenticated user object, you can use the `auth`
method in your actions. For example:

```ruby
action do
  if auth.has_access_to?(:users)
    user.destroy
  else
    error :access_denied, "This user does not have access to users"
  end
end
```

#### Restricting access to actions

There is also built-in restrictions which allow you to add restrictions at a
global and per-action basis.

The `default_access` block can be defined with your authenticator and, in
this example, will require that all users have API access.

```ruby
default_access do
  auth.has_api_access?
end
```

However, if you want to vary this on a per-action basis, you can override
it as follows by specifying the `access` block when you define your action.

```ruby
action :list do
  description "List all users"
  access { auth.has_access_to?(:users) }
  action do
    # return users here
  end
end
```

In addition to passing a block to the `access` or `default_access` methods
you can also use any of the following:

```ruby
# Ensure that the authenticated object responds to can_delete_animals? and that
# this method returns a truthy value.
access :can_delete_animals?

# Ensure that the authenticated object is a User.
access :must_be => User

# Ensure that the authenticated object is a User, responds to has_api_access?
# and that method returns a truthy value.
access :must_be => User, :with => :has_api_access?

# Ensure that the authenticated object is present. Its value is not important.
access true
```

## Working with structures

A structure is a blueprint outlining out an object can be converted into a hash
for output in your API.

Say, for example, you have a User object and you wish to present this over your
API. You would find your user and then pass this through your `user` structure
which will return an appropriate hash based on the context the structure is
being called from and your authenticated object.

### Creating a structure

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

#### Mapping

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

#### Grouping

Attributes can be placed into groups which will return a hash containing all items
within the group.

```ruby
group :financials do
  basic :balance, :type => Integer, :example => 12345
  full :last_invoice_raised_at, :type => String, :example => ""
end
```

#### Expansions

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

#### Conditional attributes

You can specify a condition on any attribute or expansion. This can be done by passing
a block to the `:if` option when defining an attribute.

```ruby
condition Proc.new { auth.is_super_special_admin? } do
  basic :pin
end
```

### Accessing structures from actions

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

## Accessing your API

The final part of this documentation is about how to access your final API.
If you're using Moonrope in a Rails application it will automatically be added
to your Rack middleware stack. If not, you'll need to add it manually.

By default, the API is exposed at `/api/v1/controller/action`.
