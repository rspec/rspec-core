Feature: treat subject as a proc

  Use `calling_it` to treat subject as a proc; replaces
  cases where `expect` would be used in "classic" syntax.

  Scenario: explicit subject
    Given a file named "calling_it_spec.rb" with:
      """
      $counter = 0
      describe 'calling_it' do
        subject { $counter += 1 }
        calling_it { should change { $counter }.by(1) }
      end
      """
    When I run `rspec calling_it_spec.rb`
    Then the examples should all pass

  Scenario: explicit subject with failure
    Given a file named "calling_it_spec_with_failure.rb" with:
      """
      $counter = 0
      describe 'calling_it' do
        subject { $counter += 1 }
        calling_it { should change { $counter }.by(2) }
      end
      """
    When I run `rspec calling_it_spec_with_failure.rb`
    Then the output should contain "1 example, 1 failure"
