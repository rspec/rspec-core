def srand(seed = 0)
  puts "WARNING: srand should always be stubbed or mocked. " +
    "This appears to be an unintended call from:\n" +
    caller[0..5].join("\n")
  seed
end

module Kernel
  def self.srand(seed = 0)
    puts "WARNING: srand should always be stubbed or mocked. " +
      "This appears to be an unintended call from:\n" +
      caller[0..5].join("\n")
    seed
  end
end

if defined?(::Random)
  class Random
    def self.srand(seed = 0)
      puts "WARNING: srand should always be stubbed or mocked. " +
        "This appears to be an unintended call from:\n" +
        caller[0..5].join("\n")
      seed
    end
  end
end
