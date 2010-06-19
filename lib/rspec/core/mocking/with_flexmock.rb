#!/usr/bin/env ruby
#
#  Created by Jim Weirich on 2007-04-10.
#  Copyright (c) 2007. All rights reserved.

require 'flexmock/rspec'

RSpec.subscribe(:before_befores) do |example|
  example.extend FlexMock::MockContainer
end

RSpec.subscribe(:before_afters) do |example|
  begin
    example.flexmock_verify
  ensure
    example.flexmock_close
  end
end
