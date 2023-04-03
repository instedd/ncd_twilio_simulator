require "spec"
require "../../src/models/simulator_command"
require "../../src/config"

describe Twiliosim::SimulatorCommand do
  describe "#parse" do
    it "returns nil when invalid" do
      command = Twiliosim::SimulatorCommand.parse("foo")
      command.should eq(nil)
    end

    it "returns a Twiliosim::OneOfCommand" do
      message = "#oneof:1,2"

      command = Twiliosim::SimulatorCommand.parse(message)
      command.is_a?(Twiliosim::OneOfCommand).should eq(true)
      command.should eq(Twiliosim::OneOfCommand.parse(message))
    end

    it "returns a Twiliosim::NumericCommand" do
      message = "#numeric:1-120"

      command = Twiliosim::SimulatorCommand.parse(message)
      command.is_a?(Twiliosim::NumericCommand).should eq(true)
      command.should eq(Twiliosim::NumericCommand.parse(message))
    end

    it "returns a Twiliosim::HangupCommand" do
      message = "#hangup"

      command = Twiliosim::SimulatorCommand.parse(message)
      command.is_a?(Twiliosim::HangupCommand).should eq(true)
      command.should eq(Twiliosim::HangupCommand.parse(message))
    end
  end

  describe Twiliosim::OneOfCommand do
    describe "#choices" do
      it "initializes OK" do
        choices = [1, 2]
        command = Twiliosim::OneOfCommand.new(choices)
        command.choices.should eq(choices)
      end
    end

    describe "#parse" do
      it "returns a Twiliosim::OneOfCommand initialized OK" do
        command = Twiliosim::OneOfCommand.parse("#oneof:1,2")
        command.should eq(Twiliosim::OneOfCommand.new([1, 2]))
      end
    end

    describe "#valid_sample" do
      it "returns a sample in choices" do
        choices = [1, 2]
        command = Twiliosim::OneOfCommand.new(choices)
        valid_sample = command.valid_sample
        choices.includes?(valid_sample).should eq(true)
      end
    end

    describe "#invalid_sample" do
      it "returns a sample not in choices" do
        choices = [1, 2]
        command = Twiliosim::OneOfCommand.new(choices)
        invalid_sample = command.invalid_sample(max_incorrect_reply_value: 5)
        choices.includes?(invalid_sample).should eq(false)
      end
    end

    describe "#sample" do
      it "returns a sample in range" do
        command = Twiliosim::NumericCommand.new(1, 2)
        valid_sample = command.sample(incorrect_reply: false, max_incorrect_reply_value: 5)
        (1..2).includes?(valid_sample.not_nil!).should eq(true)
      end

      it "returns an invalid sample" do
        command = Twiliosim::NumericCommand.new(1, 2)
        invalid_sample = command.sample(incorrect_reply: true, max_incorrect_reply_value: 5)
        (1..2).includes?(invalid_sample.not_nil!).should eq(false)
      end
    end
  end

  describe Twiliosim::NumericCommand do
    describe "#min and #max" do
      it "initializes OK" do
        command = Twiliosim::NumericCommand.new(1, 2)
        command.min.should eq(1)
        command.max.should eq(2)
      end
    end

    describe "#parse" do
      it "returns a Twiliosim::NumericCommand initialized OK" do
        command = Twiliosim::NumericCommand.parse("#numeric:1-120")
        command.should eq(Twiliosim::NumericCommand.new(1, 120))
      end
    end

    describe "#valid_sample" do
      it "returns a sample in range" do
        command = Twiliosim::NumericCommand.new(1, 2)
        valid_sample = command.valid_sample
        (1..2).includes?(valid_sample).should eq(true)
      end
    end

    describe "#invalid_sample" do
      it "returns a sample not in range" do
        command = Twiliosim::NumericCommand.new(1, 2)
        invalid_sample = command.invalid_sample(max_incorrect_reply_value: 5)
        (1..2).includes?(invalid_sample.not_nil!).should eq(false)
      end
    end

    describe "#sample" do
      it "returns a sample in range" do
        command = Twiliosim::NumericCommand.new(1, 2)
        valid_sample = command.sample(incorrect_reply: false, max_incorrect_reply_value: 5)
        (1..2).includes?(valid_sample.not_nil!).should eq(true)
      end

      it "returns an invalid sample" do
        command = Twiliosim::NumericCommand.new(1, 2)
        invalid_sample = command.sample(incorrect_reply: true, max_incorrect_reply_value: 5)
        (1..2).includes?(invalid_sample.not_nil!).should eq(false)
      end
    end
  end
end
