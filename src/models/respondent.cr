class Twiliosim::Respondent
  def Respondent.reply_message(ao_message : AOMessage) : ReplyCommand | Nil
    case ao_message.message
    when "#hangup"
      HangUp.new(ao_message)
    when /#numeric|#oneof/
      PressDigits.new(ao_message, 1)
    end
  end
end
