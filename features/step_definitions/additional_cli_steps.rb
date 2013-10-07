require 'rspec/core'  # to fix annoying "undefined method `configuration' for RSpec:Module (NoMethodError)"

Then /^the output should contain all of these:$/ do |table|
  table.raw.flatten.each do |string|
    assert_partial_output(string, all_output)
  end
end

Then /^the output should not contain any of these:$/ do |table|
  table.raw.flatten.each do |string|
    expect(all_output).not_to match(regexp(string))
  end
end

Then /^the output should contain one of the following:$/ do |table|
  matching_output = table.raw.flatten.select do |string|
    all_output =~ regexp(string)
  end

  expect(matching_output.count).to eq(1)
end

Then /^the example(?:s)? should(?: all)? pass$/ do
  step %q{the output should contain "0 failures"}
  step %q{the output should not contain "0 examples"}
  step %q{the exit status should be 0}
end

Then /^the process should succeed even though no examples were run$/ do
  step %q{the output should contain "0 examples, 0 failures"}
  step %q{the exit status should be 0}
end

Then /^the backtrace\-normalized output should contain:$/ do |partial_output|
  # ruby 1.9 includes additional stuff in the backtrace,
  # so we need to normalize it to compare it with our expected output.
  normalized_output = all_output.split("\n").map do |line|
    line =~ /(^\s+# [^:]+:\d+)/ ? $1 : line # http://rubular.com/r/zDD7DdWyzF
  end.join("\n")

  expect(normalized_output).to match(regexp(partial_output))
end

# This step can be generalized if it's ever used to test other colors
Then /^the failing example is printed in magenta$/ do
  # \e[35m = enable magenta
  # \e[0m  = reset colors
  expect(all_output).to include("\e[35m" + "F" + "\e[0m")
end
