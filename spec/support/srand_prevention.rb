RSpec.configure do |config|
  config.before do
    allow(Kernel).to receive(:srand).and_raise NotImplementedError,
      "#{Kernel}.srand should always be stubbed or mocked. " +
      "This appears to be an unintended call."

    allow(RSpec::Core::Random).to receive(:srand).and_raise NotImplementedError,
      "#{RSpec::Core::Random}.srand should always be stubbed or mocked. " +
      "This appears to be an unintended call."

    allow(RSpec::Core::RandomNumberGenerator).to receive(:srand).and_raise NotImplementedError,
      "#{RSpec::Core::RandomNumberGenerator}.srand should always be stubbed or mocked. " +
      "This appears to be an unintended call."

    if defined?(::Random)
      allow(::Random).to receive(:srand).and_raise NotImplementedError,
        "#{::Random}.srand should always be stubbed or mocked. " +
        "This appears to be an unintended call."
    end
  end
end
