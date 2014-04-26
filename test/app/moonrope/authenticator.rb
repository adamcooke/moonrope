authenticator do
  
  if request.headers['X-Moonrope-Username']
    if request.headers['X-Moonrope-Username'] == 'user' && request.headers['X-Moonrope-Password'] == 'password'
      u = User.new
      u.admin = true
      u
    else
      error :access_denied, "No suitable credentials were provided."
    end
  end
  
end
