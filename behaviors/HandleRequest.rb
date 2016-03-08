class HandleRequest
  def self.perform(request)
    case request.name
    when "Nextbus"
      when "B44"
        GetBusTimes.perform(stop_id: "901280")
    end
  end
end
