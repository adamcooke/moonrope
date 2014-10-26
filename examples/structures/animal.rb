structure :animal do
  #
  # Return basic properties about the animal.
  #
  basic do
    {:id => o.id, :name => o.name}
  end

  #
  # Return more information about the animal.
  #
  full do
    {:color => o.color, :user => structure(:user, o.user)}
  end

end
