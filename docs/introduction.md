# The key components of a Moonrope API

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
