Feature: stub with arguments

  Use `with` to constrain stubs to calls with specific arguments. This works
  like a message expectation with `any_number_of_times`: it will cause a
  failure if invoked with a different argument, but it will not cause a failure
  if it is not invoked.

  Background:
    Given a file named "account.rb" with:
    """
    class Account
      def initialize(logger)
        @logger = logger
      end

      def open
        @logger.log :open
      end
    end
    """

  Scenario: method invoked with expected argument
    Given a file named "example_spec.rb" with:
    """
    require "./account.rb"

    describe Account do
      it "can open an account" do
        logger = double('logger')
        account = Account.new(logger)
        logger.stub(:log).with(:open)
        account.open
      end
    end
    """
    When I run `rspec example_spec.rb`
    Then the examples should all pass

  Scenario: method invoked with a different argument
    Given a file named "example_spec.rb" with:
    """
    require "./account.rb"

    describe Account do
      it "can open an account" do
        logger = double('logger')
        account = Account.new(logger)
        logger.stub(:log).with(:open_account)
        account.open
      end
    end
    """
    When I run `rspec example_spec.rb`
    Then the output should contain "1 failure"
    And the output should contain:
    """
             expected: (:open_account)
                  got: (:open)
    """
