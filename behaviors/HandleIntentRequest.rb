class HandleIntentRequest
  attr_accessor :user, :request, :response

  def initialize(attributes = {})
    attributes.each { |k, v| send("#{k}=", v) }
  end

  def self.perform(*args)
    new(*args).perform
  end

  def sanitize_input(input)
    input.upcase
      .delete(" ")
      .delete(".")
  end

  def perform
    case request.name
    when "Nextbus"
      bus_name = sanitize_input(request.slots["Bus"]["value"])
      p "bus name: #{bus_name}"
      if stop = user.stops.find_by(name: bus_name)
        GetBusTimes.perform(stop_id: stop.mta_stop_id, time_to_stop: stop.time_to_stop)
      else
        "Error: I don't know that bus"
      end
    when "Newbus"
      bus_name = sanitize_input(request.slots["Bus"]["value"])
      stop_id = sanitize_input(request.slots["StopID"]["value"])
      AddNewBus.perform(user: user, name: bus_name, mta_stop_id: stop_id)
    else
      "Unrecognized request"
    end
  end
end
