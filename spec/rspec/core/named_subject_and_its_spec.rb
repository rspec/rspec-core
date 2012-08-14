class Group
  def all_members
    []
  end
  def active_members
    []
  end
end

describe Group do
  # This example group works fine...
  describe 'using let!(:group)' do
    let!(:group) { Group.new }
    subject { group }
    it                   { should be_a(Group) }
    its(:active_members) { should == group.all_members }
    its(:active_members) { group.should be_a(Group) }
    its(:active_members) { subject.should_not == group }
  end

  # I would have expected subject(:group) to work the same way, but inside of the its block, group
  # confusingly refers to the *new* subject (group.active_members) instead of to the original
  # subject to which it originally referred (Group.new).
  describe 'using subject(:group)' do
    subject(:group) { Group.new }

    # So far so good...
    it                   { should be_a(Group) }
    it                   { group.should be_a(Group) }
    it                   { group.active_members.should_not == group }
    it                   { group.active_members.should == group.all_members }

    # I would expect this to work as well, but it doesn't...
    its(:active_members) { should == group.all_members }      # undefined method `all_members' for []:Array
    its(:active_members) { group.should be_a(Group) }         # expected [] to be a kind of Group
    its(:active_members) { subject.should_not == group }      # expected not: == [], got:    []
  end
end
