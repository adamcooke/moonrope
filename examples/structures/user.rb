structure :user do
  
  #
  # Return basic properties about the user.
  #
  basic do
    {:id => o.id, :username => o.username}
  end
  
  #
  # Return more information about the user.
  #
  full do
    {:admin => o.admin}
  end
  
  #
  # Specify an expansion allowing the user's animals 
  # to be returned.
  #
  expansion :animals do
    o.animals.map { |a| structure(:animal, a) }
  end
  
  #
  # Specify a restricted attribute which is only available
  # when admin users request this structure.
  #
  restricted do
    
    # Set the condition
    condition { auth.is_a?(User) && auth.admin == true }
    
    # Set the values to be included if the condition above
    # is met.
    data do
      {:private_code => o.private_code}
    end
    
  end
  
end