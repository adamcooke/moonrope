# Authentication

Authentication consumers to your API is a key part of developing it. Moonrope's
authentication layer provides you with fine grained control of how your authentication
works while still maintaining documentability.

## Getting Started

To begin, you need to define an `authenticator`. An authenticator's role is to
extract an "identity" from an API request. In this example, we'll be authenticating
our consumers using a token that will be unique to each user. The example below
demonstrates a very simple authenticator.

```ruby
authenticator :default do

  header "X-Auth-Token", "The user's unique API token.", :example => 'f29a45f0-b6da-44ae-a029-d4e1744ebaee'

  error 'InvalidAPIToken', "The API token provided in X-Auth-Token was not valid.", :attributes => {:token => "The token that was looked up"}

  lookup do
    if token = request.headers['X-Auth-Token']
      if user = User.find_by_api_token(token)
        user
      else
        error 'InvalidAPIToken', :token => token
      end
    end
  end

  rule :default, "AccessDenied", "Must be authenticated as a user." do
    identity.is_a?(User)
  end

  rule :anonymous, "MustBeAnonymous", "Must be anonymous." do
    identity.nil?
  end

end
```

Let's break that down:

* The first line sets the name of the authenticator. In most cases you'll only
  ever have one which should be named `:default`. This will apply to all actions
  in your API.

* Next, we define a that the authenticator uses the `X-Auth-Token` header. We

  provide a description and example for documentation purposes.
* Next, we define that a `InvalidAPIToken` error may be raised when trying to
  lookup the identity for the request. We include a description plus a hash of
  attributes that should be returned with the error.

* Next, we define a `lookup` block which specifies how to lookup your identity
  object from the request. This is executed in the same scope that would be used
  for any action in the API. This block will either return the identity object,
  raise an error or return nothing. If it returns something, that will be used
  as the identity object and the request will continue. If it raises an error,
  the error will be returned to the user and the request will stop. It if returns
  nothing, the request will continue however there will be no identity.

* Next, we set a default access rule which is executed on every request to
  verify that the identity has access to the requested action. The `default` rule
  will apply to all actions however you can create others which can be chosen
  for specific actions or controllers. The block for this rule must return a true
  or false value depending on whether the identity satisfies the access condition.
  The second argument is the error code which will be returned if this condition
  is not satified for the request. The third argument is the description of the
  actual condition (for documentation).

* Finally, we define an anonymous rule which can be used for any actions where there
  should not be any identity provided.

## Choosing authenticators & access rules

When you create actions you can choose which authenticator & access rule should
be applied when the action is requested.  It's probably easiest to demonstrate
this with some code:

```ruby
controller :users do

  action :list do
    # By default, this action will use the 'default' authenticator and the
    # 'default' access rule.
  end

  action :colors do
    # This action will use the 'default' authenticator's anonymous rule.
    access_rule :anonymous
  end

  action :create do
    # This action will use the 'default' access rule on the 'two_factor
    # authenticator.
    authenticator :two_factor
  end

  action :destroy do
    # This action will use the 'admin' access rule on the 'two_factor'
    # authenticator.
    access_rule :two_factor => :admin
  end

end
```

These different actions all use different rules & authenticators. The generated
documentation will reflect these as appropriate.

It's worth noting that the `authenticator` and `access_rule` methods which are
shown here on an action, can also be applied at the controller level and they'll
apply to any actions that don't override them.
