structure :user do

  basic :id, "The user's internal system ID", :type => Integer, :eg => 123
  basic :username, "The user's unique username", :type => String, :eg => "adamcooke"
  group :name do
    basic :first, "The user's first name", :type => String, :eg => "Adam", :source_attribute => :first_name
    basic :last, "The user's last name", :type => String, :eg => "Cooke", :source_attribute => :last_name
  end

  full :admin, "Is this user an administrator?", :type => :boolean
  full :age, "The user's age", :type => Integer, :doc => false
  full :created_at, "The timestamp the user was created", :type => :timestamp
  full :updated_at, "The timestamp the user was updated", :type => :timestamp

  expansion :pets, "All pets that belong to this user", :structure => :pet, :type => Array

  expansion :balance, "The user's balance", :type => Float, :eg => 12.50 do
    o.user.balance
  end

  expansion :hidden, "This is a hidden expansion", :doc => false do
    o.user.hidden
  end

  condition Proc.new { identity.admin? }, "Can only be accessed by API users with admin access" do
    # This value will only be provided to users who are accesing the API with
    # the permission to view
    full :support_pin, "The PIN this user needs to use to access support", :type => String, :eg => "4953"
  end

  condition :default => :anonymous do
    full :mask, "The unique mask that represents this user", :type => String, :eg => 'abc123abc123'
  end

end
