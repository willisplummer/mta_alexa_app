require 'rubygems'
require 'httparty'
require 'time'
require 'bundler/setup'

class GetBusTimes
  include HTTParty
  base_uri 'http://bustime.mta.info/api'

  BUSTIME_API_KEY = ENV['BUSTIME_API_KEY']

  attr_accessor :time_to_stop, :stop_id

  def initialize(attributes = {})
    attributes.each { |k, v| send("#{k}=", v) }
  end

  def self.perform(*args)
    new(*args).perform
  end

  def perform
    times = format_times(get_bus_times)
    return "No buses found" if times == []
    times.last.insert(0, "and ")
    times = times.join(", ")
    return "Buses are arriving at #{times}."
  end

  def format_times(array)
    values = array.inject([]) do |memo, v|
      return memo if v.nil?
      time = Time.parse(v)
      memo << time.strftime("%l:%M%p") if time > Time.now + time_to_stop
      memo
    end
    return values[0..2]
  end

  def get_bus_times
    response = self.class.get("/siri/stop-monitoring.json?key=#{BUSTIME_API_KEY}&OperatorRef=MTA&MonitoringRef=#{stop_id}&MaximumStopVisits=5").to_json
    data_hash = JSON.parse(response, quirks_mode: true)
    array_of_buses = data_hash["Siri"]["ServiceDelivery"]["StopMonitoringDelivery"][0]["MonitoredStopVisit"]
    arriving_bus_times = array_of_buses.inject([]) {|memo, v| memo << v["MonitoredVehicleJourney"]["MonitoredCall"]["ExpectedArrivalTime"]; memo}
    return arriving_bus_times
  end
end
