controller :users do

  action :list do
    description "Return a list of all users"
    param :page, "The page number", :default => 1, :type => Integer
    param :per_page, "The number of items to return per page", :default => 30, :type => Integer
    action do
      paginate(User.all) do |user|
        structure user
      end
    end
  end

  action :show do
    description "Return information about a given user"
    param :username, "The user's username", :type => String, :required => true
    error "UserNotFound", "No user was found matching the given username", :attributes => {:username => "The username which was looked up"}
    action do
      if user = User.find_by_username(params.username)
        structure user, :paramable => true
      else
        error 'UserNotFound', :username => params.username
      end
    end
  end

end
