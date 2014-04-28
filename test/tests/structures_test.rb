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
  
  def test_restrictions
    user = User.new(:id => 1, :username => 'dave', :private_code => 5555)
    accessing_user = User.new(:id => 2, :username => 'admin', :admin => true)

    structure = Moonrope::Structure.new(@base, :animal) do
      basic { { :id => o.id } }
      restricted do
        condition { auth.admin == true }
        data { {:private_code => o.private_code} }
      end
    end
    
    # with auth
    authenticated_request = FakeRequest.new(:authenticated_user => accessing_user)
    hash = structure.hash(user, :full => true, :request => authenticated_request)
    assert_equal user.private_code, hash[:private_code]
    
    # no auth
    hash = structure.hash(user, :full => true)
    assert_equal nil, hash[:private_code]
  end
  
end
