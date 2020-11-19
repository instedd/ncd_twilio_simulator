require "spec"
require "../src/models/call"

include Twiliosim

describe Call do
  describe "#status" do
    it "initializes created" do
      call = Call.new("foo", "bar", "baz")

      call.status.should eq "created"
    end

    it "starts in-progress" do
      call = Call.new("foo", "bar", "baz")

      call.start

      call.status.should eq "in-progress"
    end

    it "finished completed" do
      call = Call.new("foo", "bar", "baz")

      call.finish

      call.status.should eq "completed"
    end
  end

  describe "#id" do
    it "initializes with a new (random) UUID" do
      call_0 = Call.new("foo_0", "bar_1", "baz_2")
      call_1 = Call.new("foo_1", "bar_1", "baz_1")

      call_0.id.size.should eq 36
      call_1.id.size.should eq 36
      call_0.id.should_not eq call_1.id
    end
  end

  describe "#to" do
    it "initializes OK" do
      call = Call.new("foo", "bar", "baz")

      call.to.should eq "foo"
    end
  end

  describe "#from" do
    it "initializes OK" do
      call = Call.new("foo", "bar", "baz")

      call.from.should eq "bar"
    end
  end

  describe "#account_sid" do
    it "initializes OK" do
      call = Call.new("foo", "bar", "baz")

      call.account_sid.should eq "baz"
    end
  end

  describe "#no_reply" do
    it "initializes OK" do
      call = Call.new("foo", "bar", "baz")

      call.no_reply.should eq false
    end
  end
end
