structure :user do
  
  #
  # All blocks on this page have access to a number of variables as 
  # listed below:
  # 
  #   o           =   The source object
  #   version     =   The version of the API which has been requested
  #   auth        =   The authenticating object
  #
  # In addition to these variables, you can also call `structure` to 
  # include another structure's hash.
  #
  
  #
  # Define some basic data which will be returned whenever a user 
  # is included. The most common use for this will be when displaying
  # the hash for something owner by a user.
  #
  # In this example, version 1 of the API didn't require that @ sign before
  # the username whereas all future version do.
  #
  basic do
    {
      :id => o.id,
      :username => (version == 1 ? o.username : "@#{o.username}")
    }
  end
  
  #
  # Define all the fields which exist for this structure. This information
  # will be included when the full object is requested from the API.
  #
  full do
    {
      :name => o.name,
      :age => o.age
    }
  end
  
  #
  # Set up an expansion to include all the animals which are associated with a 
  # user. In this example, we will use the animals array and link with the 
  # 'animals' structure.
  #
  expansion :animals do
    o.animals.map { |a| structure(:animal, a) }
  end
  
  #
  # The user's private code should only be available as part of the user's full
  # hash if the currently authenticated user is an admin.
  #
  restricted do
    #
    # Specify that the 'auth' object must be an admin in order to receive this
    # data.
    #
    condition do
      auth.admin == true
    end
    
    #
    # Set the data which should be included when the condition above is matched.
    # Anu number of items can be included in this hash.
    #
    data do
      {:private_code => o.private_code}
    end
  end
  
end
