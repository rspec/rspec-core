### Basics

    # create a double
    obj = double()

    # stub a method
    obj.stub(:message) # returns obj

    # specify a return value
    obj.stub(:message) { 'this is the value to return' }

### Argument constraints
   
#### Explicit arguments

    obj.stub(:message).with('an argument')
    obj.stub(:message).with('more_than', 'one_argument')

#### Argument matchers

    obj.stub(:message).with(anything())
    obj.stub(:message).with(an_instance_of(Money))
    obj.stub(:message).with(hash_including(:a => 'b'))

#### Regular expressions

    obj.stub(:message).with(/abc/)

### Raising/Throwing

    obj.stub(:message) { raise "this error" }
    obj.stub(:message) { throw :this_symbol }

### Arbitrary handling

    obj.stub(:message) do |arg1, arg2|
      # set expectations about the args in this block
      # and set a return value
    end
