RSpec.configure do |config|
  config.before do
    allow(RSpec).to receive(:warning).and_call_original
    allow(RSpec).to receive(:warning).with(/^--seed no longer automatically sets order to random/)
  end
end
