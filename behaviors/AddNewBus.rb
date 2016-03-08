class AddNewBus
  attr_accessor :name, :mta_stop_id, :user

  def initialize(attributes = {})
    attributes.each { |k, v| send("#{k}=", v) }
  end

  def self.perform(*args)
    new(*args).perform
  end

  def perform
    user.stops.create(name: name, mta_stop_id: mta_stop_id, time_to_stop: 360)
    response.add_speech("Added new bus stop named #{name}")
  end
end
