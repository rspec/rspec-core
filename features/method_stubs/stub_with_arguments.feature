Feature: stub with arguments

  You can set up more specific stubs by explicitly declaring the arguments the
  method stub can be invoked with.

  Scenario: the stub argument is not defined
    Given a file named "stub_with_arguments_spec.rb" with:
    """
    class Account
      def open(logger)
        logger.log :open
      end
    end

    describe Account do
      subject { Account.new }

      it "can open an account" do
        logger = double('logger')
        logger.stub(:log)
        subject.open logger
      end
    end
    """
    When I run `rspec stub_with_arguments_spec.rb`
    Then the examples should all pass

  Scenario: the stub argument is defined
    Given a file named "stub_with_arguments_spec.rb" with:
    """
    class Account
      def open(logger)
        logger.log :open
      end
    end

    describe Account do
      subject { Account.new }

      it "can open an account" do
        logger = double('logger')
        logger.stub(:log).with(:open)
        subject.open logger
      end
    end
    """
    When I run `rspec stub_with_arguments_spec.rb`
    Then the examples should all pass

  Scenario: the stub argument is defined but it's other than the actual value
    Given a file named "stub_with_arguments_spec.rb" with:
    """
    class Account
      def open(logger)
        logger.log :open
      end
    end

    describe Account do
      subject { Account.new }

      it "can open an account" do
        logger = double('logger')
        logger.stub(:log).with(:something_different)
        subject.open logger
      end
    end
    """
    When I run `rspec stub_with_arguments_spec.rb`
    Then the output should contain "1 example, 1 failure"
