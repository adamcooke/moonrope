# Exceptions raised during requests

Moonrope will rescue any exceptions which are raised during a Rack request.
These will be logged to the Moonrope logger and a 500 error will be returned
to the client which made the bad request.

You can also register a callback to be notified whenever an exception is raised
in the request lifecycle. This will be useful if you want to report these
exceptions to an external exception reporting service.

This is configured by registering the callback with the Moonrope::Base instance.
In a Rails application, this can be added as follows.

```ruby
Rails.application.config.moonrope.register_request_error_callback do |request, error|
  tags = {
    'component'           => 'API'
  }
  context = {
    'controller'          => request.controller.try(:name).to_s,
    'action'              => request.action.try(:name).to_s,
    'identity'            => request.identity.is_a?(ActiveRecord::Base) ? "#{request.identity.class}##{request.identity.id}" : request.identity.to_s,
    'params'              => request.params._as_hash
  }
  Raven.capture_exception(error, :tags => tags, :extra => context)
end
```
