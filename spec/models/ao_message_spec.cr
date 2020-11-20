require "spec"
require "../../src/models/ao_message"

include Twiliosim

describe AOMessage do
  describe "#message" do
    it "initializes OK" do
      ao_message = AOMessage.new("foo", "bar")

      ao_message.message.should eq "foo"
    end
  end

  describe "#redirect_url" do
    it "initializes OK" do
      ao_message = AOMessage.new("foo", "bar")

      ao_message.redirect_url.should eq "bar"
    end
  end

  describe "#to_s" do
    it "returns the string representation" do
      ao_message = AOMessage.new("foo", "bar")

      str = ao_message.to_s

      str.should eq "AOMessage - bar - foo"
    end
  end
end
