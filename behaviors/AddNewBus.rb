class AddNewBus
  attr_accessor :name, :mta_stop_id, :user

  def initialize(attributes = {})
    attributes.each { |k, v| send("#{k}=", v) }
  end

  def self.perform(*args)
    new(*args).perform
  end

  def perform
    new_stop = user.stops.create(name: name, mta_stop_id: mta_stop_id, time_to_stop: 360)
    p new_stop
    "Added new stop"
  end

  def find_stop_in_gtfs
    stop = GTFS::ORM::Stop.where(stop_id: mta_stop_id.to_s).first
    stop.nil? ? "error stop does not exist" : stop.stop_name
  end
end
