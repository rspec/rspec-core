require 'benchmark/ips'

def nested_methods
  def some_method
  end
end

def lambda_method
  some_lambda = lambda {|i|}
end


Benchmark.ips do |x|
  x.report("nested methods") do
    nested_methods
  end

  x.report("lambda") do
    lambda_method
  end

  x.compare!
end
