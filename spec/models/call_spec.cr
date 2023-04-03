require "spec"
require "../../src/models/call"

include Twiliosim

describe Call do
  describe "#new" do
    it "initializes OK" do
      call = Call.new("PN123", "PN456", "AC789", "http://web.verboice.lvh.me:8080")
      call.to.should eq "PN123"
      call.from.should eq "PN456"
      call.account_sid.should eq "AC789"
      call.url.should eq "http://web.verboice.lvh.me:8080"
      call.status.should eq("queued")
    end
  end

  describe "#status" do
    it "initializes created" do
      call = Call.new("PN123", "PN456", "AC789", "http://web.verboice.lvh.me:8080")
      call.status.should eq "queued"
    end

    it "starts in-progress" do
      call = Call.new("PN123", "PN456", "AC789", "http://web.verboice.lvh.me:8080")
      call.in_progress
      call.status.should eq "in-progress"
    end

    it "doesn't answer" do
      call = Call.new("PN123", "PN456", "AC789", "http://web.verboice.lvh.me:8080")
      call.no_answer
      call.status.should eq "no-answer"
    end

    it "failed" do
      call = Call.new("PN123", "PN456", "AC789", "http://web.verboice.lvh.me:8080")
      call.failed
      call.status.should eq "failed"
    end

    it "completed" do
      call = Call.new("PN123", "PN456", "AC789", "http://web.verboice.lvh.me:8080")
      call.completed
      call.status.should eq "completed"
    end
  end

  it "initializes with a random ID" do
    call_0 = Call.new("PN123", "PN456", "AC789", "http://web.verboice.lvh.me:8080")
    call_1 = Call.new("PN321", "PN456", "AC789", "http://web.verboice.lvh.me:8080")

    call_0.id.should_not be(nil)
    call_1.id.should_not be(nil)
    call_0.id.should_not eq(call_1.id)
  end

  it "#no_reply" do
    call = Call.new("PN123", "PN456", "AC789", "http://web.verboice.lvh.me:8080")
    call.no_reply.should eq(false)
    call.no_reply = true
    call.no_reply.should eq(true)
  end

  pending "#no_reply?" do
    # depends on App.config and value is random
  end
end
