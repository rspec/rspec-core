Feature: hyperlinks

  RSpec allows text formatters to use shell escape codes to hyperlink to the files of failed examples.

  * `hyperlink`: Should hyperlinks be displayed (default: `false`)

  @keep-ansi-escape-sequences
  Scenario: Hyperlinking failed examples
    Given a file named "hyperlinks_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.hyperlink = true
      end

      RSpec.describe "failure" do
        it "fails and includes a hyperlink" do
          expect(2).to eq(4)
        end
      end
      """
      When I run `rspec hyperlinks_spec.rb --format progress`
      Then the failed example includes shell hyperlink escape codes

  @keep-ansi-escape-sequences
  Scenario: Hyperlinking failed shared examples
    Given a file named "hyperlinks_in_shared_examples_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.hyperlink = true
      end

      RSpec.describe "shared examples" do
        shared_examples_for "failure" do
          it "fails and includes a hyperlink" do
            expect(2).to eq(4)
          end
        end

        context "first" do
          it_behaves_like "failure"
        end

        context "second" do
          it_behaves_like "failure"
        end
      end
      """
      When I run `rspec hyperlinks_in_shared_examples_spec.rb --format progress`
      Then the failed shared examples includes shell hyperlink escape codes



