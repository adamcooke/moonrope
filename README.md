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

The quickest way to get started is to install Moonrope into an existing Rails
application. You just need to pop `moonrope` into your Gemfile and restart
your server.

You should place all your configuration in a directory called RAILS_ROOT/api. 
