# Authentication

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

## Accessing the authenticated user in actions

In order to access this authenticated user object, you can use the `auth`
method in your actions. For example:

```ruby
action do
  if auth.has_access_to?(:users)
    user.destroy
  else
    # Raise an error
  end
end
```

## Restricting access to actions

As well as using the `auth` object to make decisions within an action, you can
also define a default rule which applies to all actions, access control for all
actions on a controller or per action.

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

You can also do this on a controller to override the access control on a whole
controller.

```ruby
controller :admin do
  access { auth.is_administrator? }
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
