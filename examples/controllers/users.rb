controller :users do

  #
  # Set a new before block which will be executed before all actions
  # in this controller.
  #
  before do
    if params.error
      error :parameter_error, "The `error` parameter should not be set."
    end
  end

  #
  # Set a new before block which will only run on the listed actions
  #
  before(:edit, :delete) do
    unless auth.is_a?(User) && auth.can?(:edit_users)
      error :access_denied, "User is not permitted to edit or delete users"
    end
  end

  #
  # Start defining a new controller action called list.
  #
  action :list do

    #
    # Set the description for this API action
    #
    description "Lists all users in the application"

    #
    # Set a parameter allowing the user to pass the page which is being
    # requested. By default, if not set, this value will be 1.
    #
    param :page, "The current page number for pagination.", :default => 1, :required => true
    param :status, "The status of users to display", :type => String, :regex => /\A[a-z0-9]+\z/

    #
    # Require that the autheticated user is an instance of User. This will
    # override any `default_access` which may be configured elsewhere.
    #
    access { auth.is_a?(User) && auth.can?(:manage_users) }

    #
    # Define what happens when this API action is requested.
    #
    action do
      # Set some flags which will be included with the request which
      # includes the value of the param which has been provided (or the default).
      set_flag :pagination, {:page => params.page, :total_pages => 2}

      # Set an HTTP response header
      set_header 'X-Example-Header', 'Monkeys'

      # Return a set of 30 users with example names
      (1..30).to_a.map do |i|
        structure(:user, User.new(:id => i, :username => "example#{i}"))
      end
    end

  end

end
