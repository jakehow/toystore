require 'helper'

describe Toy::Identity do
  uses_constants('User', 'Piece')

  describe "setting the key" do
    it "should set key factory to UUIDKeyFactory" do
      User.key(:uuid).should be_instance_of(Toy::Identity::UUIDKeyFactory)
    end

    it "should set key factory passed in factory" do
      factory = Toy::Identity::UUIDKeyFactory.new
      User.key(factory).should == factory
    end

    it "should use Toy.key_factory by default" do
      key_factory     = Toy::Identity::UUIDKeyFactory.new
      Toy.key_factory = key_factory
      Class.new do
        include Toy::Store
      end.key_factory.should be_instance_of(Toy::Identity::UUIDKeyFactory)
    end
  end

  describe ".next_key" do
    it "should call the next key on the key factory" do
      factory = Toy::Identity::UUIDKeyFactory.new
      factory.should_receive(:next_key).and_return('some_key')
      User.key(factory)
      User.next_key.should == 'some_key'
    end

    it "should raise an exception for nil key" do
      factory = Toy::Identity::UUIDKeyFactory.new
      factory.should_receive(:next_key).and_return(nil)
      User.key(factory)
      lambda { User.next_key }.should raise_error
    end
  end

  describe ".key_type" do
    it "returns the type based on the key factory" do
      User.key(Toy::Identity::UUIDKeyFactory.new)
      User.key_type.should be(String)
    end
  end

  describe "initializing the id" do
    it "should pass use pass the new object" do
      Piece.attribute(:name, String)
      Piece.attribute(:number, Integer)
      Piece.key(NameAndNumberKeyFactory.new)
      Piece.new(:name => 'Rook', :number => 1).id.should == 'Rook-1'
    end
  end
end
