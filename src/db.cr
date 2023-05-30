require "json"
require "mutex"
require "./models/call"

class DB
  include JSON::Serializable

  FILENAME = ENV.fetch("DB_FILE", "#{__DIR__}/../db.json")
  PERSIST  = ENV.fetch("PERSIST", "true") == "true"
  Log      = ::Log.for("twilio.simu")

  @calls : Hash(String, Twiliosim::Call)

  @[JSON::Field(ignore: true)]
  @mutex = Mutex.new

  def self.load : DB
    # if File.exists?(FILENAME)
    #   from_json(File.read(FILENAME)).tap(&.resume_calls)
    # else
    new
    # end
  end

  def initialize
    @calls = {} of String => Twiliosim::Call
  end

  def create_call(call : Twiliosim::Call) : Nil
    Log.debug { {:create, call}.inspect }

    @mutex.synchronize do
      if @calls.has_key?(call.id)
        raise "ERR: call already exists: #{call}"
      else
        @calls[call.id] = call
        save
      end
    end
  end

  def update_call(call : Twiliosim::Call) : Nil
    Log.debug { {:update, call}.inspect }

    @mutex.synchronize do
      if @calls.has_key?(call.id)
        @calls[call.id] = call
        save
      else
        raise "ERR: unknown call: #{call}"
      end
    end
  end

  # def delete_call(call : Twiliosim::Call) : Nil
  #   Log.debug { {:delete, call}.inspect }

  #   @mutex.synchronize do
  #     if @calls.has_key?(call.id)
  #       @calls.delete(call.id)
  #       save
  #     else
  #       raise "ERR: unknown call: #{call}"
  #     end
  #   end
  # end

  def resume_calls : Nil
    @calls.each_value do |call|
      Twiliosim::Simulator.spawn(call)
    end
  end

  private def save : Nil
    File.write(FILENAME, to_pretty_json) if PERSIST
  end
end
