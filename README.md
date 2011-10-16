# RSpec Mocks

rspec-mocks provides a test-double framework for rspec including support
for method stubs, fakes, and message expectations.

## Install

    gem install rspec       # for rspec-core, rspec-expectations, rspec-mocks
    gem install rspec-mocks # for rspec-mocks only

## Method Stubs

    describe "consumer" do
      it "gets stuff from a service" do
        service = double('service')
        service.stub(:find) { 'value' }
        consumer = Consumer.new(service)
        consumer.consume
        consumer.aquired_stuff.should eq(['value'])
      end
    end

## Message Expectations

    describe "some action" do
      context "when bad stuff happens" do
        it "logs the error" do
          logger = double('logger')
          doer = Doer.new(logger)
          logger.should_receive(:log).with('oops')
          doer.do_something_with(:bad_data)
        end
      end
    end

## Also see

* [http://github.com/rspec/rspec](http://github.com/rspec/rspec)
* [http://github.com/rspec/rspec-core](http://github.com/rspec/rspec-core)
* [http://github.com/rspec/rspec-expectations](http://github.com/rspec/rspec-expectations)
