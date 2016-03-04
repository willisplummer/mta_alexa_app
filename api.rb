require 'rubygems'
require 'HTTParty'
require 'bundler/setup'

MY_STOP = "901280"

class GetBusTimes
  include HTTParty
  base_uri 'http://bustime.mta.info/api'

  attr_accessor :name, :timetostop, :stop_id, :destination, :arrival_time

  def initialize(attributes = {})
    attributes.each { |k, v| send("#{k}=", v) }
  end

  def self.perform(*args)
    new(*args).perform
  end

  def perform
    puts "the g is okay" if g_ok?
    get_bus_times
  end

  def g_ok?
    true
  end

  def print_bus_times(times)
    puts "Buses are arriving at:"
    times.each do |v|
      t = Time.parse(v.to_s)
      t.strftime('%I:%M %p')
    end
  end

  def get_bus_times
    response = self.class.get("/siri/stop-monitoring.json?key=#{BUSTIME_API_KEY}&OperatorRef=MTA&MonitoringRef=#{stop_id}&MaximumStopVisits=3").to_json
    data_hash = JSON.parse(response, quirks_mode: true)
    array_of_buses = data_hash["Siri"]["ServiceDelivery"]["StopMonitoringDelivery"][0]["MonitoredStopVisit"]
    arriving_bus_times = []
    array_of_buses.each {|v| arriving_bus_times << v["MonitoredVehicleJourney"]["MonitoredCall"]["ExpectedArrivalTime"]}
    print arriving_bus_times
    print_bus_times(arriving_bus_times)
  end
end

GetBusTimes.perform
