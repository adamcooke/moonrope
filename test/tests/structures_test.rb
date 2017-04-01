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
        basic :id, :description => "The ID of the aniaml object", :example => 1, :type => Integer
        basic :name, :description => "The name of the animal", :example => "Boris", :type => String
        full :hair_color, :description => "The color of the animal's hair", :example => "Blue", :type => String, :source_attribute => :color
        expansion :user, :type => Hash, :structure => :user

        group :colors do
          basic :eye, :example => "Green", :type => String, :source_attribute => :color
          full :hair, :example => "Blue", :type => String, :source_attribute => :color
          expansion :owner, :structure => :user, :type => Hash, :source_attribute => :user
        end
      end

      structure :user do
        basic :id, :example => 1, :type => Integer
        basic :username, :example => "adam", :type => String
        expansion :animals, :type => Array, :structure => :animal, :structure_opts => {:full => true}
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
          basic :id1, :example => 1, :type => Integer, :source_attribute => :id
        end

        condition Proc.new { false } do
          basic :id2, :example => 2, :type => Integer, :source_attribute => :id
        end
      end
    end

    animal = Animal.new(:id => 1, :name => 'Fido', :color => 'Ginger')
    hash = base.structure(:animal).hash(animal)
    assert_equal 1, hash[:id1]
    assert_equal nil, hash[:id2]
  end

  def test_ifs_with_expansion
    base = Moonrope::Base.new do
      structure :animal do
        condition Proc.new { true } do
          expansion :example do
            {:hello => 'world'}
          end
        end

        condition Proc.new { false } do
          expansion :example2 do
            {:hello => 'land'}
          end
        end
      end
    end

    animal = Animal.new(:id => 1, :name => 'Fido', :color => 'Ginger')
    hash = base.structure(:animal).hash(animal, :expansions => true)
    assert_equal true, hash.keys.include?(:example)
    assert_equal false, hash.keys.include?(:example2)
  end

  def test_condition_with_description
    base = Moonrope::Base.new do
      structure :animal do
        condition Proc.new { false }, "An example description" do
          basic :id
          expansion :example do
            {:hello => 'land'}
          end
        end
      end
    end

    animal = Animal.new(:id => 1, :name => 'Fido', :color => 'Ginger')
    hash = base.structure(:animal).hash(animal, :expansions => true)
    assert_equal false, hash.keys.include?(:example)
    assert_equal false, hash.keys.include?(:id)
  end

  def test_condition_with_access_rule
    base = Moonrope::Base.new do
      authenticator :default do
        lookup { true }
        rule(:default, "NotPermitted") { true }
        rule(:false_rule, "MustNotBeFalse") { false }
      end
      structure :animal do
        condition :default => :false_rule do
          basic :id
        end

        condition :default => :default do
          basic :name
        end
      end
    end

    animal = Animal.new(:id => 1, :name => 'Fido', :color => 'Ginger')
    hash = base.structure(:animal).hash(animal, :expansions => true)
    assert_equal false, hash.keys.include?(:id)
    assert_equal true, hash.keys.include?(:name)
  end

  def test_condition_with_access_rule_and_default_authenticator
    base = Moonrope::Base.new do
      authenticator :default do
        lookup { true }
        rule(:default, "NotPermitted") { true }
        rule(:false_rule, "MustNotBeFalse") { false }
      end
      structure :animal do
        condition :false_rule do
          basic :id
        end

        condition :default do
          basic :name
        end
      end
    end

    animal = Animal.new(:id => 1, :name => 'Fido', :color => 'Ginger')
    hash = base.structure(:animal).hash(animal, :expansions => true)
    assert_equal false, hash.keys.include?(:id)
    assert_equal true, hash.keys.include?(:name)
  end


  def test_scopes
    base = Moonrope::Base.new do
      structure :animal do
        group :group1 do
          basic :id
          basic :name
          group :group2 do
            basic :id_g2, :source_attribute => :id
            basic :name2, :source_attribute => :name
            group :group3 do
              basic :id_g3, :source_attribute => :id
              basic :name3, :source_attribute => :name
            end
          end
        end

        condition Proc.new { false } do
          basic :id2, :name => :id
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

  def test_passing_values_from_the_definition
    base = Moonrope::Base.new do
      structure :animal do
        basic :example, :value => 1234
        basic :example_with_block, :value => Proc.new { "#{o.name}!!!" }
      end
    end

    animal = Animal.new(:id => 1, :name => 'Fido', :color => 'Ginger')
    hash = base.structure(:animal).hash(animal)
    assert_equal 1234, hash[:example]
    assert_equal "Fido!!!", hash[:example_with_block]
  end

  def test_creating_a_structure_with_description
    base = Moonrope::Base.new do
      structure :animal do
        basic :example, "Hello there!", :value => 1234
        basic :example2, :description => "Bananas!"
      end
    end
    assert_equal "Hello there!", base.structure(:animal).attributes[:basic].select { |a| a.name == :example }.first.description
    assert_equal "Bananas!", base.structure(:animal).attributes[:basic].select { |a| a.name == :example2 }.first.description
  end

  def test_mutating_values
    base = Moonrope::Base.new do
      structure :animal do
        basic :name, :mutation => :downcase
      end
    end
    assert_equal 'fido', base.structure(:animal).hash(Animal.new(:name => 'FIDO'))[:name]
  end

  def test_auto_mutating_values
    base = Moonrope::Base.new do
      structure :animal do
        basic :name, :type => :unix_timestamp
      end
    end
    assert_equal 1234567890, base.structure(:animal).hash(Animal.new(:name => Time.at(1234567890)))[:name]
  end

  def test_manually_selecting_attributes
    base = Moonrope::Base.new do
      structure :animal do
        basic :id
        basic :name
      end
    end
    hash = base.structure(:animal).hash(Animal.new(:id => 12345, :name => "Fido"), :attributes => [:id])
    assert_equal 12345, hash[:id]
    assert_equal false, hash.has_key?(:name)
  end


  def test_setting_options_for_embedded_expansions
    user = User.new(:id => 1, :username => 'dave')
    animal1 = Animal.new(:id => 1, :name => 'Fido', :color => 'Ginger', :user => user)
    animal2 = Animal.new(:id => 2, :name => 'Jess', :color => 'Black & White', :user => user)
    user.animals << animal1
    user.animals << animal2

    base = Moonrope::Base.new do
      structure :user do
        basic { {:id => o.id, :username => o.username } }
        expansion :animals, :structure => :animal
      end

      structure :animal do
        basic :id
        basic :name
        full :color
      end
    end

    hash = base.structure(:user).hash(user, :expansions => [{:animals => {:full => true}}])
    assert_equal 'Ginger', hash[:animals][0][:color]
  end

end
