controller :users do

  friendly_name "Users API"
  description <<-DESC
    The Users API provides full access to manage the users
    which exist on your account.
  DESC

  action :list do
    title "List all users"
    description "This action will return a list of all users which the authenticated user has access to."
    param :page, "The page number", :default => 1, :type => Integer
    param :per_page, "The number of items to return per page", :default => 30, :type => Integer
    returns :array, :structure => :user
    action do
      paginate(User.all) do |user|
        structure user, :return => true
      end
    end
  end

  action :show do
    title "Get unit information"
    param :username, "The user's username", :type => String, :required => true
    returns :hash, :structure => :user, :structure_opts => {:paramable => true}
    error "UserNotFound", "No user was found matching the given username", :attributes => {:username => "The username which was looked up"}
    action do
      if user = User.find_by_username(params.username)
        structure user, :return => true
      else
        error 'UserNotFound', :username => params.username
      end
    end
  end

  action :create do
    title "Create a new user"
    description <<-DESCRIPTION
      This action will create a new user with the properties which have been provided.
    DESCRIPTION
    param :username, "The user's username", :type => String, :required => true
    param :first_name, "The user's first name", :type => String, :required => true
    param :last_name, "The user's last name", :type => String, :required => true
    param :email_address, "The user's e-mail address", :type => String, :required => true
    param :password, "The user's password", :type => String, :required => true
    param :admin, "Should this user be an admin?", :type => :boolean
    returns :hash, :structure => :user, :structure_opts => {:full => true}
    error "ValidationError", "The details provided were not sufficient to save the user", :attributes => {:errors => "An array of errors for each field"}
    action do
      user = User.new
      user.username = params.username
      user.first_name = params.first_name
      user.last_name = params.last_name
      user.email_address = params.email_address
      user.password = params.password
      user.admin = params.admin
      if user.save
        structure user, :return => true
      else
        error 'ValidationError', :errors => user.errors
      end
    end
  end

end
