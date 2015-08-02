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

__END__

Calculating -------------------------------------
      nested methods    47.146k i/100ms
              lambda    85.962k i/100ms
-------------------------------------------------
      nested methods    731.076k (± 6.2%) i/s -      3.677M
              lambda      1.711M (± 4.5%) i/s -      8.596M

Comparison:
              lambda:  1711389.0 i/s
      nested methods:   731075.7 i/s - 2.34x slower
