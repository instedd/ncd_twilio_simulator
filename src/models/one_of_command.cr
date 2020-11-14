struct OneOfCommand
  property choices

  def initialize(@choices : Array(Int32))
  end

  def self.parse(message : String)
    if message =~ /#oneof:(\d+)(,\d+)*/
      /#oneof:(.+)/.match(message)
      choices = $~[1].split(',').map &.to_i
      OneOfCommand.new choices
    end
  end

  def sample : Int32
    @choices.sample
  end
end
