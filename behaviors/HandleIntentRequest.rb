class HandleIntentRequest
  def self.perform(request)
    case request.name
    when "Nextbus"
      case request.slots["Bus"]["value"].upcase.delete(" ")
      when "B44SBS"
        GetBusTimes.perform(stop_id: "901280", time_to_stop: 360)
      when "B45"
        GetBusTimes.perform(stop_id: "303567", time_to_stop: 360)
      when "B44"
        GetBusTimes.perform(stop_id: "303404", time_to_stop: 360)
      end
    end
  end
end
