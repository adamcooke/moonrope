authenticator do
  
  if headers['X-Moonrope-Usernane'] == 'user' && headers['X-Moonrope-Password'] == 'password'
    u = User.new
    u.admin = true
    u
  else
    false
  end
  
end
