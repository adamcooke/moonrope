structure :user do

  basic :id, "The user's internal system ID", :type => Integer, :eg => 123
  basic :username, "The user's unique username", :type => String, :eg => "adamcooke"
  basic :first_name, "The user's first name", :type => String, :eg => "Adam"
  basic :last_name, "The user's last name", :type => String, :eg => "Cooke"

  full :created_at, "The timestamp the user was created"
  full :updated_at, "The timestamp the user was updated"

end
