require 'google/apis/calendar_v3'
require 'yaml'
require 'date'

Google::Apis.logger.level = Logger::DEBUG

# Get config info
config = YAML.load_file("config/config.yml")

calendar = Google::Apis::CalendarV3::CalendarService.new
calendar.key = config['apikey']
calendarids = config['calendars']

# Get range of dates for which we want to get events
localtime = Time.now.getlocal
today = localtime.to_date
last_upcoming_event_date = today + 8
start_of_day = DateTime.parse(localtime.strftime("%Y-%m-%dT00:00:00%z"))
end_of_day = DateTime.parse(localtime.strftime("%Y-%m-%dT23:59:00%z"))
last_upcoming_event = DateTime.parse(last_upcoming_event_date.strftime("%Y-%m-%dT23:59:59%z"))

events = Array.new
upcoming = Array.new

calendarids.each do |name, id|
	entries = calendar.list_events(id,
		single_events: true,
		time_min: start_of_day.rfc3339,
	 	time_max: end_of_day.rfc3339
	)

	 upcoming_entries = calendar.list_events(id,
		single_events: true,
		time_min: end_of_day.rfc3339,
		time_max: last_upcoming_event.rfc3339
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

	unless upcoming_entries.items.empty?
		upcoming_entries.items.each do |item|
			upcoming << {
				start: item.start.date_time,
				summary: item.summary,
				description: item.description,
				location: item.location
			}
		end
	end
end

open('today.html', 'w') do |f|
	if events.empty?
		f.puts "<div class='todaytitle'>UCHICAGO PHYSICS HISTORY</div>"
		f.puts "<img src='http://physics-pics.uchicago.edu/images/1248/medium/IMG_0038.jpg' alt='Physicists in Action' class='img-responsive' />"
		f.puts "<p>If you can identify any people in this picture, please email maryh@hep.uchicago.edu about image #1248.</p>"
	else
		sorted = events.sort_by { |x| x[:start] }

		f.puts "<div class='todaytitle'>TODAY'S EVENTS</div>"
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

open('upcoming.html','w') do |f|
	sorted = upcoming.sort_by { |x| x[:start] }
	f.puts "<div class='todaytitle'>UPCOMING EVENTS</div>"
	sorted.each do |event|
		f.puts "<div class='timeroom'>"
		f.puts "<span class='left'>#{event[:start].strftime("%A, %B %-d at %-l:%M %p")}</span><span class='right'>#{event[:location]}</span>"
		f.puts "</div>"
		f.puts "<div class='summary'>#{event[:summary]}</div>"
		f.puts "<hr />"
		# puts event[:summary]
		# #puts event[:description]
		# puts event[:start].strftime("%-l:%M %p")
		# puts event[:location]
		# puts "====="
	end
	f.puts "</div>"
end

