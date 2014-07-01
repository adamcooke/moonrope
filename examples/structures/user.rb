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
    
end