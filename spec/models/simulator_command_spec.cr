require "spec"
require "../../src/models/simulator_command"
require "../../src/config"

include Twiliosim

describe SimulatorCommand do
  describe "#parse" do
    it "returns nil when invalid" do
      simulator_command = SimulatorCommand.parse("foo")

      simulator_command.should eq nil
    end

    it "returns a OneOfCommand" do
      message = "#oneof:1,2"

      simulator_command = SimulatorCommand.parse(message)

      simulator_command.is_a?(OneOfCommand).should eq true
      simulator_command.should eq OneOfCommand.parse(message)
    end

    it "returns a NumericCommand" do
      message = "#numeric:1-2"

      simulator_command = SimulatorCommand.parse(message)

      simulator_command.is_a?(NumericCommand).should eq true
      simulator_command.should eq NumericCommand.parse(message)
    end
  end

  describe OneOfCommand do
    describe "#choices" do
      it "initializes OK" do
        foo = [1, 2]

        simulator_command = OneOfCommand.new(foo)

        simulator_command.choices.should eq foo
      end
    end

    describe "#parse" do
      it "returns a OneOfCommand initialized OK" do
        foo = [1, 2]
        control_command = OneOfCommand.new(foo)
        message = "#oneof:1,2"

        parsed_command = OneOfCommand.parse(message)

        parsed_command.should eq control_command
      end
    end

    describe "#valid_sample" do
      it "returns a sample in choices" do
        choices = [1, 2]
        simulator_command = OneOfCommand.new(choices)

        valid_sample = simulator_command.valid_sample

        choices.includes?(valid_sample).should eq true
      end
    end

    describe "#invalid_sample" do
      it "returns a sample not in choices" do
        choices = [1, 2]
        simulator_command = OneOfCommand.new(choices)

        invalid_sample = simulator_command.invalid_sample(Config.load)

        choices.includes?(invalid_sample).should eq false
      end
    end
  end

  describe NumericCommand do
    describe "#min" do
      it "initializes OK" do
        min = 1
        max = 2

        simulator_command = NumericCommand.new(min, max)

        simulator_command.min.should eq min
      end
    end

    describe "#max" do
      it "initializes OK" do
        min = 1
        max = 2

        simulator_command = NumericCommand.new(min, max)

        simulator_command.max.should eq max
      end
    end

    describe "#parse" do
      it "returns a NumericCommand initialized OK" do
        min = 1
        max = 2
        control_command = NumericCommand.new(min, max)
        message = "#numeric:#{min}-#{max}"

        parsed_command = NumericCommand.parse(message)

        parsed_command.should eq control_command
      end
    end

    describe "#valid_sample" do
      it "returns a sample in range" do
        min = 1
        max = 2
        simulator_command = NumericCommand.new(min, max)

        valid_sample = simulator_command.valid_sample

        (min..max).to_a.includes?(valid_sample).should eq true
      end
    end

    describe "#invalid_sample" do
      it "returns a sample not in range" do
        min = 1
        max = 2
        simulator_command = NumericCommand.new(min, max)

        invalid_sample = simulator_command.invalid_sample(Config.load)

        (min..max).to_a.includes?(invalid_sample).should eq false
      end
    end
  end
end
