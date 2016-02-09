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

  param_set :properties do
    param :username, "The user's username", :type => String
    param :first_name, "The user's first name", :type => String
    param :last_name, "The user's last name", :type => String
    param :email_address, "The user's e-mail address", :type => String
    param :password, "The user's password", :type => String
    param :admin, "Should this user be an admin?", :type => :boolean
  end

  action :create do
    title "Create a new user"
    description <<-DESCRIPTION
      This action will create a new user with the properties which have been provided.
    DESCRIPTION
    param_set :properties, :required => [:username, :first_name, :last_name, :email_address, :password]
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

  action :update do
    title "Update an existing user"
    description "This action will update an existing user with the properties provided."
    param :id, "The ID of the user to update", :type => Integer, :required => true
    param_set :properties
    returns :hash, :structure => :user, :structure_opts => {:full => true}
    error 'UserNotFound', "The user specified could not be found", :attributes => {:id => "The ID that was looked up"}
    error "ValidationError", "The details provided were not sufficient to save the user", :attributes => {:errors => "An array of errors for each field"}
    action do
      user = User.find_by_id(params.id) || error('UserNotFound', :id => params.id)
      user.username = params.username             if params.has?(:username)
      user.first_name = params.first_name         if params.has?(:first_name)
      user.last_name = params.last_name           if params.has?(:last_name)
      user.email_address = params.email_address   if params.has?(:email_address)
      user.password = params.password             if params.has?(:password)
      user.admin = params.admin                   if params.has?(:admin)
      if user.save
        structure user, :return => true
      else
        error 'ValidationError', :errors => user.errors
      end
    end
  end

end
