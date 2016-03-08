class HandleIntentRequest
  def self.perform(user, request)
    case request.name
    when "Nextbus"
      bus_name = request.slots["Bus"]["value"].upcase.delete(" ")
      p "bus name: #{bus_name}"
      if stop = user.stops.find(name: bus_name)
        GetBusTimes.perform(stop_id: stop.mta_stop_id, time_to_stop: stop.time_to_stop)
      else
        "Error: I don't know that bus"
      end
    end
  end
end
