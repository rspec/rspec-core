# Deliberately named _specs.rb to avoid being loaded except when specified

RSpec.describe "Order1" do
  it("passes") { expect(1).to eq 1 }
end
