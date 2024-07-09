# Deliberately named _specs.rb to avoid being loaded except when specified

require "rspec/core/resources/bisect/frieren_quote"

RSpec.describe "Order2" do
  before { FrierenQuote.change }

  it("passes") { expect(1).to eq 1 }
end
