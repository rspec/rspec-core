1.upto(20) do |i|
  RSpec.describe "Group #{i}" do
    1.upto(20) do |i2|
      example("ex #{i2}", :apply_it) { }

      context "nested #{i2}" do
        1.upto(20) do |i3|
          example("ex #{i3}", :apply_it) { }
        end
      end
    end
  end
end

RSpec::Core::Runner.invoke
