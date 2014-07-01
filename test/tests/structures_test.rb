class StructuresTest < Test::Unit::TestCase
  
  def setup
    @base = Moonrope::Base.new
  end
  
  def test_structure_creation
    structure = Moonrope::Structure.new(@base, :user) do
      basic { {:id => o.id} }
      full  { {:username => o.username} }
    end
    assert_equal Moonrope::Structure, structure.class
    assert structure.basic.is_a?(Proc)
    assert structure.full.is_a?(Proc)
  end
  
  def test_structure_hash_with_basic_data
    structure = Moonrope::Structure.new(@base, :user) do
      basic { {:id => o.id} }
      full  { {:username => o.username} }
    end
    
    user = User.new(:id => 1, :username => 'adam')
    
    hash = structure.hash(user)
    assert_equal user.id, hash[:id]
    assert_equal false, hash.keys.include?(:username)
    
    hash = structure.hash(user, :full => true)
    assert_equal user.id, hash[:id]
    assert_equal user.username, hash[:username]
  end
  
  def test_passing_the_version
    structure = Moonrope::Structure.new(@base, :user) do
      basic do 
        {
          :id => o.id,
          :username => (version == 1 ? o.username : "@#{o.username}") 
        }
      end
    end
    user = User.new(:id => 1, :username => 'adam')
    # check version 2
    request = FakeRequest.new(:version => 2)
    hash = structure.hash(user, :request => request)
    assert_equal "@#{user.username}", hash[:username]
    # check version 1
    request = FakeRequest.new(:version => 1)
    hash = structure.hash(user, :request => request)
    assert_equal user.username, hash[:username]
  end
  
  def test_structure_hash_with_expansions
    user = User.new(:id => 1, :username => 'dave')
    animal1 = Animal.new(:id => 1, :name => 'Fido', :color => 'Ginder', :user => user)
    animal2 = Animal.new(:id => 2, :name => 'Jess', :color => 'Black & White', :user => user)
    user.animals << animal1
    user.animals << animal2
    
    base = Moonrope::Base.new do
      structure :user do
        basic { {:id => o.id, :username => o.username } }
        expansion :animals do
          o.animals.map { |a| structure(:animal, a) }
        end
      end
      
      structure :animal do
        basic { {:id => o.id, :name => o.name} }
        full { {:color => o.color, :user => structure(:user, o.user)} }
      end
    end
    
    animal_structure = base.structure(:animal)
    
    # Test the full animal structure includes the user
    hash = animal_structure.hash(animal1, :full => true)
    assert_equal animal1.name, hash[:name]
    assert_equal user.username, hash[:user][:username]
    
    # Test that a user structure with expansions includes the
    # animals which are included
    user_structure = base.structure(:user)
    hash = user_structure.hash(user, :expansions => true)
    assert hash[:animals].is_a?(Array), "hash[:animals] is not an array"
    assert_equal hash[:animals][0][:name], 'Fido'
    assert_equal hash[:animals][1][:name], 'Jess'
    
    # Test that when expansions was false
    hash = user_structure.hash(user, :expansions => false)
    assert_equal nil, hash[:animals], "hash[:animals] is present"
    
    # Test cases when expansions are provided as an array
    hash = user_structure.hash(user, :expansions => [:something, :else])
    assert_equal nil, hash[:animals], "hash[:animals] is present"
    hash = user_structure.hash(user, :expansions => [:animals])
    assert_equal Array, hash[:animals].class, "hash[:animals] is present"
  end
    
  def test_structured_structures
    base = Moonrope::Base.new do
      structure :animal do
        basic :id, "The ID of the aniaml object", :example => 1, :type => Integer
        basic :name, "The name of the animal", :example => "Boris", :type => String
        full :hair_color, "The color of the animal's hair", :example => "Blue", :type => String, :name => :color
        expansion :user, "The associated user", :type => Hash, :structure => :user
        
        group :colors do
          basic :eye, "The animal's eye color", :example => "Green", :type => String, :name => :color
          full :hair, "The animals hair color", :example => "Blue", :type => String, :name => :color
          expansion :owner, "The animal's owner", :structure => :user, :type => Hash, :name => :user
        end
      end
      
      structure :user do
        basic :id, "The ID of the user object", :example => 1, :type => Integer
        basic :username, "The username", :example => "adam", :type => String
        expansion :animals, "The animals with this user", :type => Array, :structure => :animal, :structure_opts => {:full => true}
      end
    end
    
    user = User.new(:id => 1, :username => 'adam', :private_code => 9876)
    animal = Animal.new(:id => 1, :name => 'Fido', :color => 'Ginger', :user => user)
    user.animals << animal
    animal2 = Animal.new(:id => 2, :name => 'Boris', :color => 'Black', :user => user)
    user.animals << animal2
    
    # a full hash with all expansions
    hash = base.structure(:animal).hash(animal, :full => true, :expansions => true)
    # standard attributes
    assert_equal 1, hash[:id]
    assert_equal 'Fido', hash[:name]
    assert_equal 'Ginger', hash[:hair_color]
    # expansion in a group
    assert_equal Hash, hash[:colors][:owner].class
    # normal expansion
    assert_equal Hash, hash[:user].class
    assert_equal 'adam', hash[:user][:username]
    assert_equal nil, hash[:user][:animals]
    # group
    assert_equal Hash, hash[:colors].class
    assert_equal 'Ginger', hash[:colors][:eye]
    assert_equal 'Ginger', hash[:colors][:hair]
    
    # basic hash
    hash = base.structure(:animal).hash(animal)
    # normal attributes
    assert_equal 1, hash[:id]
    assert_equal 'Fido', hash[:name]
    # groups
    assert_equal Hash, hash[:colors].class
    assert_equal 'Ginger', hash[:colors][:eye]
    assert_equal nil, hash[:colors][:hair]
    
    # a full user hash with all expansions
    hash = base.structure(:user).hash(user, :full => true, :expansions => true)
    # arrays
    assert_equal Array, hash[:animals].class
    assert_equal 'Fido', hash[:animals][0][:name]
    assert_equal 'Boris', hash[:animals][1][:name]
    assert_equal 'Black', hash[:animals][1][:hair_color]
  end
  
  def test_ifs
    base = Moonrope::Base.new do
      structure :animal do
        condition Proc.new { true } do
          basic :id1, "The ID1 of the aniaml object", :example => 1, :type => Integer, :name => :id
        end
        
        condition Proc.new { false } do
          basic :id2, "The ID2 of the aniaml object", :example => 2, :type => Integer, :name => :id
        end
      end
    end
    
    animal = Animal.new(:id => 1, :name => 'Fido', :color => 'Ginger')
    hash = base.structure(:animal).hash(animal)
    assert_equal 1, hash[:id1]
    assert_equal nil, hash[:id2]
  end
  
  def test_scopes
    base = Moonrope::Base.new do
      structure :animal do
        group :group1 do
          basic :id, "The ID of the animal"
          basic :name, "Name"
          group :group2 do
            basic :id_g2, "ID", :name => :id
            basic :name2, "Name", :name => :name
            group :group3 do
              basic :id_g3, "ID", :name => :id
              basic :name3, "Name", :name => :name
            end
          end
        end
        
        condition Proc.new { false } do
          basic :id2, "ID2", :name => :id
        end
      end
    end
    animal = Animal.new(:id => 1, :name => 'Fido', :color => 'Ginger')
    hash = base.structure(:animal).hash(animal, :full => true)

    assert_equal 1, hash[:group1][:id]
    assert_equal 1, hash[:group1][:group2][:id_g2]
    assert_equal 1, hash[:group1][:group2][:group3][:id_g3]

    assert_equal 'Fido', hash[:group1][:name]
    assert_equal 'Fido', hash[:group1][:group2][:name2]
    assert_equal 'Fido', hash[:group1][:group2][:group3][:name3]

    # id2 shouldn't exist because it's if block returns false
    assert_equal false, hash.keys.include?(:id2)
  end
  
end
