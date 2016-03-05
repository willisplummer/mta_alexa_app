require 'rubygems'
require 'httparty'
require 'time'
require 'bundler/setup'

class GetBusTimes
  include HTTParty
  base_uri 'http://bustime.mta.info/api'

  BUSTIME_API_KEY = ENV['BUSTIME_API_KEY']

  attr_accessor :name, :timetostop, :stop_id, :destination, :arrival_time

  def initialize(attributes = {})
    attributes.each { |k, v| send("#{k}=", v) }
  end

  def self.perform(*args)
    new(*args).perform
  end

  def perform
    format_times(get_bus_times)
  end

  def format_times(hash)
    hash.inject([]) {|memo, v| memo << Time.parse(v).strftime("%H:%M%p"); memo}
  end

  def get_bus_times
    response = self.class.get("/siri/stop-monitoring.json?key=#{BUSTIME_API_KEY}&OperatorRef=MTA&MonitoringRef=#{stop_id}&MaximumStopVisits=3").to_json
    data_hash = JSON.parse(response, quirks_mode: true)
    array_of_buses = data_hash["Siri"]["ServiceDelivery"]["StopMonitoringDelivery"][0]["MonitoredStopVisit"]
    arriving_bus_times = array_of_buses.inject([]) {|memo, v| memo << v["MonitoredVehicleJourney"]["MonitoredCall"]["ExpectedArrivalTime"]}
    return arriving_bus_times
  end
end
