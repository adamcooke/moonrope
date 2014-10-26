#
# By default, if an action doesn't specify an access condition,
# assume access is granted if the authentication object is an
# instance of User.
#
default_access do
  auth.is_a?(User)
end

#
# Set up an authenticator to set how an authenticating user will
# be determined for the request. In this instance, we will look at
# the request headers X-Username and X-Password and if they are valid
# we will return a user object.
#
authenticator do

  if request.headers['X-Username'] == 'username' && request.headers == ['X-Password']
    User.new(:id => 100, :username => 'auth-user')
  else
    error :access_denied, "Supplied username & password was incorrect."
  end

end
