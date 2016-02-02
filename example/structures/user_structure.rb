structure :user do

  basic :id, "The user's internal system ID", :type => Integer, :eg => 123
  basic :username, "The user's unique username", :type => String, :eg => "adamcooke"
  group :name do
    basic :first, "The user's first name", :type => String, :eg => "Adam", :source_attribute => :first_name
    basic :last, "The user's last name", :type => String, :eg => "Cooke", :source_attribute => :last_name
  end

  full :admin, "Is this user an administrator?", :type => :boolean, :eg => false
  full :created_at, "The timestamp the user was created", :type => :timestamp
  full :updated_at, "The timestamp the user was updated", :type => :timestamp

end
