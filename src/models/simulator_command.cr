module Twiliosim
  abstract struct SimulatorCommand
    def self.parse(message : String) : SimulatorCommand?
      {{ @type.all_subclasses }}.each do |klass|
        if command = klass.parse(message)
          return command
        end
      end
    end

    def valid_sample : Int32
      raise "NotImplementedError: {{@type}}#valid_sample"
    end

    def invalid_sample(max_incorrect_reply_value : Int32) : Int32?
      raise "NotImplementedError: {{@type}}#invalid_sample"
    end

    def sample(incorrect_reply : Bool, max_incorrect_reply_value : Int32) : Int32?
      if incorrect_reply
        invalid_sample(max_incorrect_reply_value)
      else
        valid_sample
      end
    end
  end

  struct HangupCommand < SimulatorCommand
    def self.parse(message : String) : self?
      if message =~ /#hangup/
        new
      end
    end
  end

  struct OneOfCommand < SimulatorCommand
    def self.parse(message : String) : self?
      if message =~ /#oneof:(.+)/
        new($1.split(',').map(&.to_i))
      end
    end

    getter choices

    def initialize(@choices : Array(Int32))
    end

    def valid_sample : Int32
      @choices.sample
    end

    def invalid_sample(max_incorrect_reply_value : Int32) : Int32?
      # restrict candidates by config
      invalid_candidates = (0..max_incorrect_reply_value).to_a
      # restrict candidates by command
      invalid_candidates = invalid_candidates.reject! { |x| @choices.includes?(x) }
      # pick a random candidate
      invalid_candidates.sample unless invalid_candidates.empty?
    end
  end

  struct NumericCommand < SimulatorCommand
    def self.parse(message : String) : self?
      if message =~ /#numeric:\s*(\d+)\s*-\s*(\d+)/
        new($1.to_i, $2.to_i)
      end
    end

    getter min
    getter max

    def initialize(@min : Int32, @max : Int32)
    end

    def valid_sample : Int32
      rand(@min..@max)
    end

    def invalid_sample(max_incorrect_reply_value : Int32) : Int32?
      # restrict candidates by config
      invalid_candidates = (0..max_incorrect_reply_value).to_a
      # restrict candidates by command
      invalid_candidates = invalid_candidates.reject!(@min..@max)
      # pick a random candidate
      invalid_candidates.sample unless invalid_candidates.empty?
    end
  end
end
