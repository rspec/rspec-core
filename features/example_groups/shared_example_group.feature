@shared_examples_for @it_behaves_like
Feature: shared example group

  Shared example groups let you describe behaviour of types or modules. When
  declared, a shared group's content is stored. It is only realized in the
  context of another example group, which provides any context the shared group
  needs to run.
  
  While describing the behaviour of object or module you may find that the 
  functionality is similar to another set of examples you previously described.
  Instead of repeating yourself, you can instead extract the set of examples
  and place them into their own group 'shared_example_for'. 
  
  For each of the objects you are attempting to describe, you can now declare
  that they exhibit this behavior by stating that 'it_behaves_like'.
  
  
  Scenario: shared examples group
    Given a file named "dangerous_items.rb" with:
    """
    shared_examples_for "something that is dangerous" do
      
      it "should be lethal if used in large doses" do
        true
      end
      
      it "should require a license to operate" do
        true
      end
      
    end
    
    describe "Radiation" do
      it_behaves_like "something that is dangerous"
    end
    
    describe "Love" do
      it_behaves_like "something that is dangerous"
    end

    """
    When I run "rspec dangerous_items.rb --format documentation"
    Then the examples should all pass
    And the output should contain:
      """
      Radiation
        behaves like something that is dangerous
          should be lethal if used in large doses
          should require a license to operate

      Love
        behaves like something that is dangerous
          should be lethal if used in large doses
          should require a license to operate
      """
  
  @described_class
  Scenario: shared example group applied to two groups
    Given a file named "collection_spec.rb" with:
    """
    require "set"

    shared_examples_for "a collection" do
      let(:collection) { described_class.new([7, 2, 4]) }

      context "initialized with 3 items" do
        it "says it has three items" do
          collection.size.should eq(3)
        end
      end

      describe "#include?" do
        context "with an an item that is in the collection" do
          it "returns true" do
            collection.include?(7).should be_true
          end
        end

        context "with an an item that is not in the collection" do
          it "returns false" do
            collection.include?(9).should be_false
          end
        end
      end
    end

    describe Array do
      it_behaves_like "a collection"
    end

    describe Set do
      it_behaves_like "a collection"
    end
    """
    When I run "rspec collection_spec.rb --format documentation"
    Then the examples should all pass
    And the output should contain:
      """
      Array
        behaves like a collection
          initialized with 3 items
            says it has three items
          #include?
            with an an item that is in the collection
              returns true
            with an an item that is not in the collection
              returns false

      Set
        behaves like a collection
          initialized with 3 items
            says it has three items
          #include?
            with an an item that is in the collection
              returns true
            with an an item that is not in the collection
              returns false
      """

  Scenario: Providing context to a shared group using a block
    Given a file named "shared_example_group_spec.rb" with:
    """
    require "set"

    shared_examples_for "a collection object" do
      describe "<<" do
        it "adds objects to the end of the collection" do
          collection << 1
          collection << 2
          collection.to_a.should eq([1,2])
        end
      end
    end

    describe Array do
      it_should_behave_like "a collection object" do
        let(:collection) { Array.new }
      end
    end

    describe Set do
      it_should_behave_like "a collection object" do
        let(:collection) { Set.new }
      end
    end
    """
    When I run "rspec shared_example_group_spec.rb --format documentation"
    Then the examples should all pass
    And the output should contain:
      """
      Array
        it should behave like a collection object
          <<
            adds objects to the end of the collection

      Set
        it should behave like a collection object
          <<
            adds objects to the end of the collection
      """

  Scenario: Passing parameters to a shared example group
    Given a file named "shared_example_group_params_spec.rb" with:
    """
    shared_examples_for "a measurable object" do |measurement, measurement_methods|
      measurement_methods.each do |measurement_method|
        it "should return #{measurement} from ##{measurement_method}" do
          subject.send(measurement_method).should == measurement
        end
      end
    end

    describe Array, "with 3 items" do
      subject { [1, 2, 3] }
      it_should_behave_like "a measurable object", 3, [:size, :length]
    end

    describe String, "of 6 characters" do
      subject { "FooBar" }
      it_should_behave_like "a measurable object", 6, [:size, :length]
    end
    """
    When I run "rspec shared_example_group_params_spec.rb --format documentation"
    Then the examples should all pass
    And the output should contain:
      """
      Array with 3 items
        it should behave like a measurable object
          should return 3 from #size
          should return 3 from #length

      String of 6 characters
        it should behave like a measurable object
          should return 6 from #size
          should return 6 from #length
      """

  @aliasing @configuration
  Scenario: Aliasing "it_should_behave_like" to "it_has_behavior"
    Given a file named "shared_example_group_spec.rb" with:
      """
      RSpec.configure do |c|
        c.alias_it_should_behave_like_to :it_has_behavior, 'has behavior:'
      end

      shared_examples_for 'sortability' do
        it 'responds to <=>' do
          sortable.should respond_to(:<=>)
        end
      end

      describe String do
        it_has_behavior 'sortability' do
          let(:sortable) { 'sample string' }
        end
      end
      """
    When I run "rspec shared_example_group_spec.rb --format documentation"
    Then the examples should all pass
    And the output should contain:
      """
      String
        has behavior: sortability
          responds to <=>
      """
