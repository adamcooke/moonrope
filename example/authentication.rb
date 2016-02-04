authenticator :default do

  description <<-DESCRIPTION
    To authenticate to the API, you need to pass an appropriate API token with your
    request. To find out how to obtain an API token, please refer to the Authentication
    API documentaton which outlines the available methods available for this.
  DESCRIPTION

  header "X-Auth-Application", "The API application which is generated by us and provided to you.", :example => "abc123abc123abc123"
  header "X-Auth-Token", "The API token for the user you wish to authenticate as.", :example => "abc123abc123abc123"

  error "InvalidApplicationToken", "The application token provided in X-Auth-Application is not valid.", :attributes => {:token => "The token used to find the application"}
  error "InvalidAuthToken", "The auth token provided in X-Auth-Token is not valid.", :attributes => {:token => "The token that was used"}
  error "ExpiredAuthToken", "The auth token provided in X-Auth-Token has expired.", :attributes => {:expired_at => "The time the token expired"}

  lookup do
    if app_token = header['X-Auth-Application']
      api_application = APIApplication.find_by_token(app_token)
      if api_application.nil?
        error "InvalidApplicationToken", :token => app_token
      end

      if auth_token = header['X-Auth-Token']
        api_token = api_application.api_tokens.find_by_token(auth_token)
        if api_token.nil? || api_token.inactive?
          error "InvalidAuthToken", :token => auth_token
        end

        if api_token.expired?
          error "ExpiredAuthToken", :expired_at => api_token.expired_at
        end

        api_token
      else
        :anonymous
      end
    end
  end

  rule :default, "NotAuthenticated", "Must be authenticated with a valid user API token." do
    auth.is_a?(APIToken) && auth.user
  end

  rule :must_be_admin, "MustBeAdmin", "Must be authenticated as a valid admin user." do
    auth.is_a?(APIToken) && auth.user && auth.user.admin?
  end

  rule :anonymous, "MustBeAnonymous", "Must not be authenticated (no auth headers provided)." do
    auth == :anonymous
  end

end
