require 'helper'

describe Toy::Persistence do
  uses_constants('User')

  let(:klass) do
    Class.new { include Toy::Store }
  end

  describe ".store" do
    it "sets if arguments and reads if not" do
      User.store(:memory, {})
      User.store.should == Adapter[:memory].new({})
    end

    it "defaults options to empty hash" do
      Adapter[:memory].should_receive(:new).with({}, {})
      User.store(:memory, {})
    end

    it "works with options" do
      Adapter[:memory].should_receive(:new).with({}, :something => true)
      User.store(:memory, {}, :something => true)
    end

    it "raises argument error if name provided but not client" do
      lambda do
        klass.store(:memory)
      end.should raise_error(ArgumentError, 'Client is required')
    end

    it "raises argument error if no name or client provided and has not been set" do
      lambda do
        klass.store
      end.should raise_error(StandardError, 'No store has been set')
    end
  end

  describe ".has_store?" do
    it "returns true if store set" do
      klass.store(:memory, {})
      klass.has_store?.should be_true
    end

    it "returns false if store not set" do
      klass.has_store?.should be_false
    end
  end

  describe ".create" do
    before do
      User.attribute :name, String
      User.attribute :age, Integer
      @doc = User.create(:name => 'John', :age => 50)
    end
    let(:doc) { @doc }

    it "creates key in database with attributes" do
      User.store.read(doc.id).should == {
        'name' => 'John',
        'age'  => 50,
      }
    end

    it "returns instance of model" do
      doc.should be_instance_of(User)
    end
  end

  describe ".delete(*ids)" do
    it "should delete a single record" do
      doc = User.create
      User.delete(doc.id)
      User.key?(doc.id).should be_false
    end

    it "should delete multiple records" do
      doc1 = User.create
      doc2 = User.create

      User.delete(doc1.id, doc2.id)

      User.key?(doc1.id).should be_false
      User.key?(doc2.id).should be_false
    end

    it "should not complain when records do not exist" do
      doc = User.create
      User.delete("taco:bell:tacos")
    end
  end

  describe ".destroy(*ids)" do
    it "should destroy a single record" do
      doc = User.create
      User.destroy(doc.id)
      User.key?(doc.id).should be_false
    end

    it "should destroy multiple records" do
      doc1 = User.create
      doc2 = User.create

      User.destroy(doc1.id, doc2.id)

      User.key?(doc1.id).should be_false
      User.key?(doc2.id).should be_false
    end

    it "should not complain when records do not exist" do
      doc = User.create
      User.destroy("taco:bell:tacos")
    end
  end

  describe "#store" do
    it "delegates to class" do
      User.new.store.should equal(User.store)
    end
  end

  describe "#new_record?" do
    it "returns true if new" do
      User.new.should be_new_record
    end

    it "returns false if not new" do
      User.create.should_not be_new_record
    end
  end

  describe "#persisted?" do
    it "returns true if persisted" do
      User.create.should be_persisted
    end

    it "returns false if not persisted" do
      User.new.should_not be_persisted
    end

    it "returns false if deleted" do
      doc = User.create
      doc.delete
      doc.should_not be_persisted
    end
  end

  describe "#save" do
    before do
      User.attribute :name, String
      User.attribute :age, Integer
      User.attribute :accepted_terms, Boolean, :virtual => true
    end

    context "with new record" do
      before do
        @doc = User.new(:name => 'John', :age => 28, :accepted_terms => true)
        @doc.save
      end

      it "saves to key" do
        User.key?(@doc.id)
      end

      it "does not persist virtual attributes" do
        @doc.store.read(@doc.id).should_not include('accepted_terms')
      end
    end

    context "with existing record" do
      before do
        @doc      = User.create(:name => 'John', :age => 28)
        @key      = @doc.id
        @value    = User.store.read(@doc.id)
        @doc.name = 'Bill'
        @doc.accepted_terms = false
        @doc.save
      end
      let(:doc) { @doc }

      it "stores in same key" do
        doc.id.should == @key
      end

      it "updates value in store" do
        User.store.read(doc.id).should_not == @value
      end

      it "does not persist virtual attributes" do
        @doc.store.read(@doc.id).should_not include('accepted_terms')
      end

      it "updates the attributes in the instance" do
        doc.name.should == 'Bill'
      end
    end
  end

  describe "#update_attributes" do
    before do
      User.attribute :name, String
    end

    it "should change attribute and save" do
      user = User.create(:name => 'John')
      User.get(user.id).name.should == 'John'

      user.update_attributes(:name => 'Geoffrey')
      User.get(user.id).name.should == 'Geoffrey'
    end
  end

  describe "#delete" do
    it "should remove the instance from the store" do
      doc = User.create
      doc.delete
      User.key?(doc.id).should be_false
    end
  end

  describe "#destroy" do
    it "should remove the instance from the store" do
      doc = User.create
      doc.destroy
      User.key?(doc.id).should be_false
    end
  end

  describe "#destroyed?" do
    it "should be false if not deleted" do
      doc = User.create
      doc.should_not be_destroyed
    end

    it "should be true if deleted" do
      doc = User.create
      doc.delete
      doc.should be_destroyed
    end
  end
end