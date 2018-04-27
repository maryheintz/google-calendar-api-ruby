require 'google/apis/calendar_v3'
require 'yaml'
require 'date'

#Google::Apis.logger.level = Logger::DEBUG

# Get config info
config = YAML.load_file("config/config.yml")

calendar = Google::Apis::CalendarV3::CalendarService.new
calendar.key = config['apikey']
calendarids = config['calendars']

# Get today & tomorrow which is used for the range 
today = Date.today
tomorrow = today + 1
start_of_day = today.to_datetime.rfc3339
end_of_day = start_of_day.gsub("T00:00","T23:59")

events = Array.new

calendarids.each do |name, id|
	entries = calendar.list_events(id,
		always_include_email: false,
		single_events: true,
		time_min: start_of_day,
	 	time_max: end_of_day
	)
	
	unless entries.items.empty?
		entries.items.each do |item|
			events << { 
				start: item.start.date_time, 
				summary: item.summary, 
				description: item.description, 
				location: item.location
			}
		end
	end
end

unless events.empty?
	sorted = events.sort_by { |x| x[:start] }

	open('today.html', 'w') do |f|
		sorted.each do |event|
			f.puts "<span class='left'>#{event[:start].strftime("%-l:%M %p")}</span><span class='right'>#{event[:location]}</span>"
			f.puts "#{event[:summary]}"
			f.puts "<hr />"
			# puts event[:summary]
			# #puts event[:description]
			# puts event[:start].strftime("%-l:%M %p")
			# puts event[:location]
			# puts "====="
		end
	end
end
