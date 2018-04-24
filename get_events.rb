require 'google/apis/calendar_v3'
require 'yaml'

#Google::Apis.logger.level = Logger::DEBUG

# Get config info
config = YAML.load_file("config/config.yml")

calendar = Google::Apis::CalendarV3::CalendarService.new
calendar.key = config['apikey']
calendarids = config['calendars']

events = Array.new

calendarids.each do |name, id|
	entries = calendar.list_events(id,
		always_include_email: false,
		time_min: '2018-04-23T00:00:00-05:00',
	 	time_max: '2018-04-23T23:59:59-05:00'
	)

	entries.items.each do |item|
		events << { 
			start: item.start.date_time, 
			summary: item.summary, 
			description: item.description, 
			location: item.location
		}
	end
end

events.each do |event|
	puts event[:summary]
	puts event[:description]
	puts event[:start]
	puts event[:location]
	puts "====="
end