structure :pet do

  basic :id, "The ID of the pet", :type => Integer, :eg => 148
  basic :name, "The name of the pet", :type => String, :eg => "Fido"
  basic :color, "What color is the pet?", :type => String, :eg => "Green"

  expansion :user, "The user who owns this pet", :type => Hash, :structure => :user

end
