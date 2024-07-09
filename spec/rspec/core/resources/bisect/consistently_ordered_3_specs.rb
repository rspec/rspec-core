# Deliberately named _specs.rb to avoid being loaded except when specified

require "rspec/core/resources/bisect/frieren_quote"

RSpec.describe "Order3" do
  it("fails order-dependency")  { expect(FrierenQuote.one).to eq "That is what hero Himmel would have done." }
end
