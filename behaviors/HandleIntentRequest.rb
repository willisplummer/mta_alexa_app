class HandleIntentRequest

  def self.perform(user, request, response)
    case request.name
    when "Nextbus"
      bus_name = request.slots["Bus"]["value"].upcase.delete(" ")
      p "bus name: #{bus_name}"
      if stop = user.stops.find_by(name: bus_name)
        GetBusTimes.perform(stop_id: stop.mta_stop_id, time_to_stop: stop.time_to_stop)
      else
        "Error: I don't know that bus"
      end
    when "Newstop"
      bus_name = request.slots["Bus"]["value"].upcase.delete(" ")
      stop_id = request.slots["StopID"]["value"].delete(" ")
      AddNewBus.perform(user: user, name: bus_name, mta_stop_id: stop_id)
    else
      "Unrecognized request"
    end
  end
end
