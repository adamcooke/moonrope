# Moonrope

Moonrope is an API server & client tool for Ruby/Rack applications. It
provides everything you need to create an API within your application and 
have a Ruby API client provided without any development.

This repository is the server-side library which allows you to easily define
your API actions & data structures and serve them out using Rack middleware.

* [Documentation](http://rdoc.info/github/viaduct/moonrope/master/frames)
* [Travis CI](https://travis-ci.org/viaduct/moonrope)

To get started, the best place to look is our
[examples directory](http://github.com/https://github.com/viaduct/moonrope/tree/master/examples)
which includes examples of how to define structures and controllers.

## Usage

To get started, you need to create a new base API instance which is aware of
all your defined controllers & structures. If you just have a directory of 
these files, you can easily load it as follows:

```ruby
moonrope = Moonrope::Base.load('path/to/directory')
```

This `moonrope` instance contains all the information about your API. All 
interactions your application has with your API will go through this.

