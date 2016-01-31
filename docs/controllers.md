# Controllers & Actions

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

## Parameters

It's very common to need to receive additional information when the request
is made. Moonrope allows you to receive parameters into your action like
normal HTTP requests.

To access a paremters within your action (or helper), you can simply access
it using `params[:name_of_parameter]` or `params.name_of_parameter`. For example,
if you wanted to access a parameter named `page` you can use `params[:page]` or
`params.page`. If the value sent is nil or an empty string this will return nil.

### Defining supported parameters

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

## Raising errors

If an action cannot be completed, you'll need to return an error. So that Moonrope
can document your API, you need to define all the types of error that an action
can return.

```ruby
action :show do
  error "ApplicationSuspended", "The application ({app_name}) you're trying to access is suspended.", :attributes => {:app_name => "The name of the application"}
  action do
    if application.suspended?
      error "ApplicationSuspended", :app_name => application.name
    end
  end
end
```

In this example, you're defining an error called `ApplicationSuspended` along
with some information about what it means plus an array of attributes which will
be returned with it. When you're actually in the action, you're going to call that
error by specifying the name and the attributes to provide. This will then be
returned to the user along with the previously defined message and attributes.

These will always be returned to the consumer with the `error` status.

## Flags

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
