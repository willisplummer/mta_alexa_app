class GetTrainTimes
  MTA_API_KEY = ENV['MTA_API_KEY']
  include HTTParty
  base_uri "http://datamine.mta.info/mta_esi.php?key=#{MTA_API_KEY}&feed_id=1"

  MTA_API_KEY = ENV['BUSTIME_API_KEY']

  attr_accessor :time_to_stop, :stop_id

  def initialize(attributes = {})
    attributes.each { |k, v| send("#{k}=", v) }
  end

  def self.perform(*args)
    new(*args).perform
  end

  def perform
    times = format_times(get_times)
    return "No trains found" if times == []
    times.last.insert(0, "and ")
    times = times.join(", ")
    return "Trains are arriving at #{times}."
  end

  def get_times
  end
end
