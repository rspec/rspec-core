require 'spec_helper'

describe RSpec do
  describe "::configuration" do
    it "returns the same object every time" do
      expect(RSpec.configuration).to equal(RSpec.configuration)
    end
  end

  describe "::configuration=" do
    it "sets the configuration object" do
      configuration = RSpec::Core::Configuration.new

      RSpec.configuration = configuration

      expect(RSpec.configuration).to equal(configuration)
    end
  end

  describe "::configure" do
    it "yields the current configuration" do
      RSpec.configure do |config|
        expect(config).to equal(RSpec::configuration)
      end
    end
  end

  describe "::world" do
    it "returns the same object every time" do
      expect(RSpec.world).to equal(RSpec.world)
    end
  end

  describe "::world=" do
    it "sets the world object" do
      world = RSpec::Core::World.new

      RSpec.world = world

      expect(RSpec.world).to equal(world)
    end
  end

  describe "::reset" do
    it "resets the configuration and world objects" do
      config_before_reset = RSpec.configuration
      world_before_reset  = RSpec.world

      RSpec.reset

      expect(RSpec.configuration).not_to equal(config_before_reset)
      expect(RSpec.world).not_to equal(world_before_reset)
    end
  end
end
