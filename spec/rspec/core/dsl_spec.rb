require 'rspec/support/spec/in_sub_process'

main = self

RSpec.describe "The RSpec DSL" do
  include RSpec::Support::InSubProcess

  shared_examples_for "dsl methods" do |*method_names|
    it 'are only available off of `RSpec`' do
      in_sub_process do
        setup

        expect(::RSpec).to respond_to(*method_names)

        expect(main).not_to respond_to(*method_names)
        expect(Module.new).not_to respond_to(*method_names)
        expect(Object.new).not_to respond_to(*method_names)
      end
    end
  end

  describe "built in DSL methods" do
    include_examples "dsl methods", :describe, :context, :shared_examples, :shared_examples_for, :shared_context do
      def setup
      end
    end
  end

  describe "custom example group aliases" do
    context "when adding aliases before exposing the DSL globally" do
      include_examples "dsl methods", :detail do
        def setup
          RSpec.configuration.alias_example_group_to(:detail)
        end
      end
    end

    context "when adding duplicate aliases" do
      it "only a single alias is created" do
        in_sub_process do
          RSpec.configuration.alias_example_group_to(:detail)
          RSpec.configuration.alias_example_group_to(:detail)
          expect(RSpec::Core::DSL.example_group_aliases.count(:detail)).to eq(1)
        end
      end
    end
  end
end
