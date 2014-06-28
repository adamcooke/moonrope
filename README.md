# Moonrope

Moonrope is an API server & client tool for Ruby/Rack applications. It
provides everything you need to create an API within your application and 
have a Ruby API client provided without any development.

This repository is the server-side library which allows you to easily define
your API actions & data structures and serve them out using Rack middleware.

* [Documentation](http://rdoc.info/github/viaduct/moonrope/master/frames)
* [Travis CI](https://travis-ci.org/viaduct/moonrope)

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
  param :name, "The person's name", :required => true, :type => String
  param :age, "The person's age", :required => true, :type => Integer
  param :hair_color, "The person's hair color", :type => String, :default => 'Unknown'
  param :phone_number, "The phone number", :type => String, :regex => /\A\+[\d\s]+\z/
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

## Working with structures


