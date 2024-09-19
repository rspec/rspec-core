# Deliberately named _specs.rb to avoid being loaded except when specified

RSpec.describe "output capture" do
  it "can still capture output when running under --bisect" do
    expect { puts "hi" }.to output("hi\n").to_stdout_from_any_process
  end
end
