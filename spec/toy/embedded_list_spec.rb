require 'helper'

describe Toy::List do
  uses_constants('Game', 'Move')

  before do
    @list = Game.embedded_list(:moves)
  end

  let(:list)  { @list }

  it "has model" do
    list.model.should == Game
  end

  it "has name" do
    list.name.should == :moves
  end

  it "has type" do
    list.type.should == Move
  end

  it "has instance_variable" do
    list.instance_variable.should == :@_moves
  end

  it "adds list to model" do
    Game.embedded_lists.keys.should include(:moves)
  end

  it "adds reader method" do
    Game.new.should respond_to(:moves)
  end

  it "adds writer method" do
    Game.new.should respond_to(:moves=)
  end

  describe "#eql?" do
    it "returns true if same class, model, and name" do
      list.should eql(list)
    end

    it "returns false if not same class" do
      list.should_not eql({})
    end

    it "returns false if not same model" do
      list.should_not eql(Toy::List.new(Move, :moves))
    end

    it "returns false if not the same name" do
      list.should_not eql(Toy::List.new(Game, :recent_moves))
    end
  end

  describe "setting list type" do
    before do
      @list = Game.embedded_list(:recent_moves, Move)
    end
    let(:list) { @list }

    it "uses type provided instead of inferring from name" do
      list.type.should be(Move)
    end

    it "works properly when reading and writing" do
      game = Game.create
      move = Move.create
      game.recent_moves         = [move]
      game.recent_moves.should == [move]
    end
  end

  describe "list reader" do
    before do
      Move.attribute(:index, Integer)
      @game = Game.create(:move_attributes => [{:index => 0}, {:index => 1}])
    end

    it "returns instances" do
      @game.moves.each do |move|
        move.should be_instance_of(Move)
      end
      @game.moves[0].id.should_not be_nil
      @game.moves[1].id.should_not be_nil
      @game.moves[0].index.should == 0
      @game.moves[1].index.should == 1
    end

    it "sets reference to parent for each instance" do
      @game.moves.each do |move|
        move.parent_reference.should == @game
      end
    end
  end

  describe "list writer" do
    before do
      @move1 = Move.new
      @move2 = Move.new
      @game  = Game.create(:moves => [@move2])
    end

    it "set attribute" do
      @game.move_attributes.should == [@move2.attributes]
    end

    it "unmemoizes reader" do
      @game.moves.should == [@move2]
      @game.moves         = [@move1]
      @game.moves.should == [@move1]
    end

    it "sets reference to parent for each instance" do
      @game.moves.each do |move|
        move.parent_reference.should == @game
      end
    end
  end

  describe "list attribute writer" do
    before do
      Move.attribute(:index, Integer)
      @game = Game.new('move_attributes' => [
        {'index' => '1'}
      ])
    end

    it "typecasts hash values correctly" do
      @game.move_attributes.should == [
        {'id' => @game.moves[0].id, 'index' => 1}
      ]
    end

    it "accepts hash of hashes" do
      game = Game.new('move_attributes' => {
        '0' => {'index' => 1},
        '1' => {'index' => 2},
        '2' => {'index' => 3},
      })
      game.move_attributes.should == [
        {'id' => game.moves[0].id, 'index' => 1},
        {'id' => game.moves[1].id, 'index' => 2},
        {'id' => game.moves[2].id, 'index' => 3},
      ]
    end

    it "sets ids if present" do
      game = Game.new('move_attributes' => [
        {'id' => 'foo', 'index' => '1'}
      ])
      game.move_attributes.should == [
        {'id' => 'foo', 'index' => 1},
      ]
    end
  end

  describe "list#push" do
    before do
      @move = Move.new
      @game = Game.new
      @game.moves.push(@move)
    end

    it "raises error if wrong type assigned" do
      lambda {
        @game.moves.push(Game.new)
      }.should raise_error(ArgumentError, "Move expected, but was Game")
    end

    it "sets reference to parent" do
      # right now pushing a move adds a different instance to the proxy
      # so i'm checking that it adds reference to both
      @game.moves.each do |move|
        move.parent_reference.should == @game
      end
      @move.parent_reference.should == @game
    end

    it "instances should not be persisted" do
      @game.moves.each do |move|
        move.should_not be_persisted
      end
    end

    it "marks instances as persisted when parent saved" do
      @game.save
      @game.moves.each do |move|
        move.should be_persisted
      end
    end

    it "should save list" do
      moves = @game.moves.target
      @game.save
      @game.reload
      @game.moves.should == moves
    end

    it "should keep existing instances as persisted when adding a new instance" do
      @game.save
      @game.moves.push(Move.new)
      @game.moves.first.should be_persisted
      @game.moves.last.should_not be_persisted
    end

    it "marks instances as persisted when updated" do
      @game.save
      game = @game.reload
      move = Move.new
      game.moves.push(move)
      move.should_not be_persisted
      game.save
      game.moves.each do |move|
        move.should be_persisted
      end
      # move.should be_persisted
    end
  end

  describe "list#<<" do
    before do
      @move = Move.new
      @game = Game.new
      @game.moves << @move
    end

    it "raises error if wrong type assigned" do
      lambda {
        @game.moves << Game.new
      }.should raise_error(ArgumentError, "Move expected, but was Game")
    end

    it "sets reference to parent" do
      # right now pushing a move adds a different instance to the proxy
      # so i'm checking that it adds reference to both
      @game.moves.each do |move|
        move.parent_reference.should == @game
      end
      @move.parent_reference.should == @game
    end

    it "instances should not be persisted" do
      @game.moves.each do |move|
        move.should_not be_persisted
      end
    end

    it "marks instances as persisted when parent saved" do
      @game.save
      @game.moves.each do |move|
        move.should be_persisted
      end
    end
  end

  describe "list#concat" do
    before do
      @move1 = Move.new
      @move2 = Move.new
      @game  = Game.new
      @game.moves.concat(@move1, @move2)
    end

    it "raises error if wrong type assigned" do
      lambda {
        @game.moves.concat(Game.new, Move.new)
      }.should raise_error(ArgumentError, "Move expected, but was Game")
    end

    it "sets reference to parent" do
      # right now pushing a move adds a different instance to the proxy
      # so i'm checking that it adds reference to both
      @game.moves.each do |move|
        move.parent_reference.should == @game
      end
      @move1.parent_reference.should == @game
      @move2.parent_reference.should == @game
    end

    it "instances should not be persisted" do
      @game.moves.each do |move|
        move.should_not be_persisted
      end
    end

    it "marks instances as persisted when parent saved" do
      @game.save
      @game.moves.each do |move|
        move.should be_persisted
      end
    end
  end

  describe "list#concat (with array)" do
    before do
      @move1 = Move.new
      @move2 = Move.new
      @game  = Game.create
      @game.moves.concat([@move1, @move2])
    end

    it "raises error if wrong type assigned" do
      lambda {
        @game.moves.concat([Game.new, Move.new])
      }.should raise_error(ArgumentError, "Move expected, but was Game")
    end

    it "sets reference to parent" do
      # right now pushing a move adds a different instance to the proxy
      # so i'm checking that it adds reference to both
      @game.moves.each do |move|
        move.parent_reference.should == @game
      end
      @move1.parent_reference.should == @game
      @move2.parent_reference.should == @game
    end

    it "instances should not be persisted" do
      @game.moves.each do |move|
        move.should_not be_persisted
      end
    end

    it "marks instances as persisted when parent saved" do
      @game.save
      @game.moves.each do |move|
        move.should be_persisted
      end
    end
  end

  shared_examples_for("embedded_list#create") do
    it "creates instance" do
      @move.should be_persisted
    end

    it "assigns reference to parent" do
      @move.parent_reference.should == @game
    end

    it "assigns id" do
      @move.id.should_not be_nil
    end

    it "adds instance to reader" do
      @game.moves.should == [@move]
    end

    it "marks instance as persisted" do
      @move.should be_persisted
    end
  end

  describe "list#create" do
    before do
      @game = Game.create
      @move = @game.moves.create
    end

    it_should_behave_like "embedded_list#create"
  end

  describe "list#create (with attributes)" do
    before do
      Move.attribute(:move_index, Integer)
      @game = Game.create
      @move = @game.moves.create(:move_index => 0)
    end

    it_should_behave_like "embedded_list#create"

    it "sets attributes on instance" do
      @move.move_index.should == 0
    end
  end

  describe "list#create (invalid)" do
    before do
      @game = Game.create
      @game.moves.should_not_receive(:push)
      @game.moves.should_not_receive(:reset)
      @game.should_not_receive(:reload)
      @game.should_not_receive(:save)

      Move.attribute(:move_index, Integer)
      Move.validates_presence_of(:move_index)

      @move = @game.moves.create
    end

    it "returns instance" do
      @move.should be_instance_of(Move)
    end

    it "is not persisted" do
      @move.should_not be_persisted
    end

    it "assigns reference to parent" do
      @move.parent_reference.should == @game
    end
  end

  describe "list#create (valid with invalid root that validates embedded)" do
    before do
      Game.attribute(:user_id, String)
      Game.validates_presence_of(:user_id)

      @game = Game.new
      @move = @game.moves.create
    end

    it "is not persisted" do
      @move.should_not be_persisted
    end

    it "is persisted when root is valid and saved" do
      @game.user_id = '1'
      @game.save!
      @move.should be_persisted
    end
  end

  describe "list#destroy" do
    before do
      Move.attribute(:move_index, Integer)
      @game = Game.create
      @move1 = @game.moves.create(:move_index => 0)
      @move2 = @game.moves.create(:move_index => 1)
    end

    it "should take multiple ids" do
      @game.moves.destroy(@move1.id, @move2.id)
      @game.moves.should be_empty
      @game.reload
      @game.moves.should be_empty
    end

    it "should take an array of ids" do
      @game.moves.destroy([@move1.id, @move2.id])
      @game.moves.should be_empty
      @game.reload
      @game.moves.should be_empty
    end

    it "should take a block to filter on" do
      @game.moves.destroy { |move| move.move_index == 1 }
      @game.moves.should == [@move1]
      @game.reload
      @game.moves.should == [@move1]
    end
  end

  describe "list#destroy_all" do
    before do
      Move.attribute(:move_index, Integer)
      @game = Game.create
      @move1 = @game.moves.create(:move_index => 0)
      @move2 = @game.moves.create(:move_index => 1)
    end

    it "should destroy all" do
      @game.moves.destroy_all
      @game.moves.should be_empty
      @game.reload
      @game.moves.should be_empty
    end
  end

  describe "list#each" do
    before do
      @move1 = Move.new
      @move2 = Move.new
      @game  = Game.create(:moves => [@move1, @move2])
    end

    it "iterates through each instance" do
      moves = []
      @game.moves.each do |move|
        moves << move
      end
      moves.should == [@move1, @move2]
    end
  end

  describe "enumerating" do
    before do
      Move.attribute(:move_index, Integer)
      @move1 = Move.new(:move_index => 0)
      @move2 = Move.new(:move_index => 1)
      @game  = Game.create(:moves => [@move1, @move2])
    end

    it "works" do
      @game.moves.select { |move| move.move_index > 0 }.should == [@move2]
      @game.moves.reject { |move| move.move_index > 0 }.should == [@move1]
    end
  end

  describe "list#include?" do
    before do
      @move1 = Move.new
      @move2 = Move.new
      @game = Game.create(:moves => [@move1])
    end

    it "returns true if instance in association" do
      @game.moves.should include(@move1)
    end

    it "returns false if instance not in association" do
      @game.moves.should_not include(@move2)
    end

    it "returns false for nil" do
      @game.moves.should_not include(nil)
    end
  end

  describe "list with block" do
    before do
      Move.attribute(:old, Boolean)
      Game.embedded_list(:moves) do
        def old
          target.select { |move| move.old? }
        end
      end

      @move_new = Move.create(:old => false)
      @move_old = Move.create(:old => true)
      @game     = Game.create(:moves => [@move_new, @move_old])
    end

    it "extends block methods onto proxy" do
      @game.moves.respond_to?(:old).should be_true
      @game.moves.old.should == [@move_old]
    end
  end

  describe "list extension with :extensions option" do
    before do
      old_module = Module.new do
        def old
          target.select { |m| m.old? }
        end
      end

      recent_proc = Proc.new do
        def recent
          target.select { |m| !m.old? }
        end
      end

      Move.attribute(:old, Boolean)
      Game.embedded_list(:moves, :extensions => [old_module, recent_proc])

      @move_new = Move.new(:old => false)
      @move_old = Move.new(:old => true)
      @game     = Game.create(:moves => [@move_new, @move_old])
    end

    it "extends modules" do
      @game.moves.respond_to?(:old).should be_true
      @game.moves.old.should    == [@move_old]
    end

    it "extends procs" do
      @game.moves.respond_to?(:recent).should be_true
      @game.moves.recent.should == [@move_new]
    end
  end

  describe "list#get" do
    before do
      @game = Game.create
      @move = @game.moves.create
    end

    it "should not find items that don't exist" do
      @game.moves.get('does-not-exist').should be_nil
    end

    it "should find items that are in list" do
      @game.moves.get(@move.id).should == @move
    end
  end

  describe "list#get!" do
    before do
      @game = Game.create
      @move = @game.moves.create
    end

    it "should not find items that don't exist" do
      lambda {
        @game.moves.get!('does-not-exist')
      }.should raise_error(Toy::NotFound, 'Could not find document with id: "does-not-exist"')
    end

    it "should find items that are in list" do
      @game.moves.get!(@move.id).should == @move
    end
  end
end