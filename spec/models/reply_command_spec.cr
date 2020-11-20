require "spec"
require "../../src/models/ao_message"
require "../../src/models/reply_command"

include Twiliosim

describe PressDigits do
  describe "#ao_message" do
    it "initializes OK" do
      ao_message = AOMessage.new("foo", "bar")
      foo = 28

      reply_command = PressDigits.new(ao_message, foo)

      reply_command.ao_message.should eq ao_message
    end
  end

  describe "#digits" do
    it "initializes OK" do
      ao_message = AOMessage.new("foo", "bar")
      foo = 53

      reply_command = PressDigits.new(ao_message, foo)

      reply_command.digits.should eq foo
    end
  end

  describe "#to_s" do
    it "returns the string representation" do
      ao_message = AOMessage.new("foo", "bar")
      foo = 95
      reply_command = PressDigits.new(ao_message, foo)

      str = reply_command.to_s

      str.should eq "PressDigits < ReplyCommand #{foo}"
    end
  end
end

describe HangUp do
  describe "#ao_message" do
    it "initializes OK" do
      ao_message = AOMessage.new("foo", "bar")
      foo = 28

      reply_command = HangUp.new(ao_message)

      reply_command.ao_message.should eq ao_message
    end
  end

  describe "#to_s" do
    it "returns the string representation" do
      ao_message = AOMessage.new("foo", "bar")
      reply_command = HangUp.new(ao_message)

      str = reply_command.to_s

      str.should eq "HangUp < ReplyCommand"
    end
  end
end
