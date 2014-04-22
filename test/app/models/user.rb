class User
  
  attr_accessor :id
  attr_accessor :username
  attr_accessor :name
  attr_accessor :date_of_birth
  
  def age
    ((Time.now - date_of_birth) / 60 / 60 / 24 / 365).round
  end
  
  def animals
    @animals ||= Array.new
  end
  
end
