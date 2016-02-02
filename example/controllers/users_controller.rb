controller :users do

  friendly_name "Users API"
  description <<-DESC
    The Users API provides full access to manage the users
    which exist on your account.
  DESC

  action :list do
    description "Return a list of all users"
    param :page, "The page number", :default => 1, :type => Integer
    param :per_page, "The number of items to return per page", :default => 30, :type => Integer
    returns :array, :structure => :user
    action do
      paginate(User.all) do |user|
        structure user
      end
    end
  end

  action :show do
    description "Return information about a given user"
    param :username, "The user's username", :type => String, :required => true
    returns :hash, :structure => :user
    error "UserNotFound", "No user was found matching the given username", :attributes => {:username => "The username which was looked up"}
    action do
      if user = User.find_by_username(params.username)
        structure user, :paramable => true
      else
        error 'UserNotFound', :username => params.username
      end
    end
  end

  action :save do
    description "Create or update a user"
    param :id, "The ID of the existing user to be updated (do not send to create a new user)", :type => Integer
    param :username, "The user's username", :type => String, :set => true
    param :first_name, "The user's first name", :type => String, :set => true
    param :last_name, "The user's last name", :type => String, :set => true
    param :email_address, "The user's e-mail address", :type => String, :set => :create_only
    param :password, "The user's password", :type => String, :set => :update_only
    param :admin, "Should this user be an admin?", :type => :boolean, :set => true
    returns :hash, :structure => :user, :structure_opts => {:full => true}
    error "ValidationError", "The details provided were not sufficient to save the user", :attributes => {:errors => "An array of errors for each field"}
    error "UserNotFound", "No existing user was found for the ID provider", :attributes => {:id => "The ID which was looked up"}
    action do
      if params.id
        user = User.find_by_id(params.id)
        if user.nil?
          error "UserNotFound", :id => params.id
        end
      else
        user = User.new
      end
      auto_set_params_for user
      if user.save
        structure user, :full => true
      else
        error 'ValidationError', :errors => user.errors
      end
    end
  end

end
