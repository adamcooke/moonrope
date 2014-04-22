structure :animal do
  
  basic do
    {
      :id => o.id,
      :type => o.type,
      :name => o.name
    }
  end
  
  full do
    {
      :color => o.color,
      :gender => o.gender,
      :user => structure(:user, o.user)
    }
  end
  
end