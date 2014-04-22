structure :user do
  
  #
  # Set some basic attributes for the user
  #
  basic do
    {
      :id => o.id,
      :username => o.username
    }
  end
  
  #
  # Set some extra attributes for a user
  #
  full do
    {
      :name => o.name,
      :age => o.age
    }
  end
  
  expansion :animals do
    o.animals.map { |a| structure(:animal, a) }
  end
  
end