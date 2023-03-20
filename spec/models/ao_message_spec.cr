require "spec"
require "../../src/models/ao_message"

describe Twiliosim::AOMessage do
  it "Say + Redirect" do
    twiml = <<-XML
      <?xml charset="utf-8"?>
      <Response>
        <Say>command</Say>
        <Redirect>http://web.verboice.lvh.me:8080/VerboiceSid=123</Redirect>
      </Response>
    XML

    msg = Twiliosim::AOMessage.new(twiml)
    msg.message.should eq(twiml)
    msg.received_at.should_not eq(nil)

    msg.crashed?.should eq(false)
    msg.gather?.should eq(nil)
    msg.play?.should eq(nil)
    msg.say?.should eq("command")
    msg.redirect?.should eq("http://web.verboice.lvh.me:8080/VerboiceSid=123")
    msg.hangup?.should eq(false)
  end

  it "Gather + Say + Redirect" do
    twiml = <<-XML
      <?xml charset="utf-8"?>
      <Response>
        <Gather timeout="10">
          <Say>command</Say>
        </Gather>
        <Redirect>http://web.verboice.lvh.me:8080/VerboiceSid=123</Redirect>
      </Response>
    XML

    msg = Twiliosim::AOMessage.new(twiml)
    msg.message.should eq(twiml)
    msg.received_at.should_not eq(nil)

    msg.crashed?.should eq(false)
    msg.gather?.try(&.timeout).should eq(10)
    msg.play?.should eq(nil)
    msg.say?.should eq("command")
    msg.redirect?.should eq("http://web.verboice.lvh.me:8080/VerboiceSid=123")
    msg.hangup?.should eq(false)
  end

  it "Say + Hangup" do
    twiml = <<-XML
      <?xml charset="utf-8"?>
      <Response>
        <Say>Thank you</Say>
        <Hangup/>
      </Response>
    XML

    msg = Twiliosim::AOMessage.new(twiml)
    msg.message.should eq(twiml)
    msg.received_at.should_not eq(nil)

    msg.crashed?.should eq(false)
    msg.play?.should eq(nil)
    msg.gather?.should eq(nil)
    msg.say?.should eq("Thank you")
    msg.redirect?.should eq(nil)
    msg.hangup?.should eq(true)
  end

  it "Play (not supported)" do
    twiml = <<-XML
      <?xml charset="utf-8"?>
      <Response>
        <Play>http://host:port/path/to/audio.mp3</Play>
      </Response>
    XML

    msg = Twiliosim::AOMessage.new(twiml)
    msg.message.should eq(twiml)
    msg.received_at.should_not eq(nil)

    msg.crashed?.should eq(false)
    msg.play?.should eq("http://host:port/path/to/audio.mp3")
  end

  it "crashed verboice" do
    twiml = <<-HTML
      <HTML>...</HTML>
    HTML

    msg = Twiliosim::AOMessage.new(twiml)
    msg.message.should eq(twiml)
    msg.received_at.should_not eq(nil)

    msg.crashed?.should eq(true)
    msg.play?.should eq(nil)
    msg.gather?.should eq(nil)
    msg.say?.should eq(nil)
    msg.redirect?.should eq(nil)
    msg.hangup?.should eq(false)
  end
end
