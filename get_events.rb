require 'google/apis/calendar_v3'
require 'yaml'
require 'date'
require 'time'

#Google::Apis.logger.level = Logger::DEBUG

# Get config info
config = YAML.load_file("config/config.yml")

calendar = Google::Apis::CalendarV3::CalendarService.new
calendar.key = config['apikey']
calendarids = config['calendars']

# Get range of dates for which we want to get events
localtime = Time.now.getlocal
today = localtime.to_date
tomorrow_date = Time.now.getlocal + 86400 # Have to add seconds when working with time 86400 = 60 secs * 60 min * 24 hours
last_upcoming_event_date = today + 8
start_of_day = DateTime.parse(localtime.strftime("%Y-%m-%dT00:00:00%z"))
end_of_day = DateTime.parse(localtime.strftime("%Y-%m-%dT23:59:00%z"))
tomorrow = DateTime.parse(tomorrow_date.strftime("%Y-%m-%dT00:00:00%z"))
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
		time_min: tomorrow.rfc3339,
		time_max: last_upcoming_event.rfc3339
	)

	unless entries.items.empty?
		entries.items.each do |item|
			if item.start.date_time.nil?
				item.start.date_time = DateTime.parse(item.start.date)
			end
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
			if item.start.date_time.nil?
				item.start.date_time = DateTime.parse(item.start.date)
			end
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
		# Get list of files need help identifying
		pics = File.readlines("#{HOME}/scripts/physics-pics.txt")
		sample = pics.sample
		pic = sample.split(', ')
		pic_id = pic[0]
		pic_url = pic[1].chomp

		# Get list of files of old pics we know about
		historical = File.readlines("#{HOME}/scripts/historical.txt")
		historical_sample = historical.sample
		historical_pic = historical_sample.split(', ')
		hist_id = historical_pic[0]
		hist_url = historical_pic[1]
		hist_caption = historical_pic[2].chomp

		# Get list of files in faculty that may show
		faculty = Array.new
		fac_caption = Array.new
		people = Dir.glob("#{HOME}/html/faculty/*txt")
		people.each do |fac|
		  temp = fac.split('.')
		  name = temp[0].slice(22..-1)
		  faculty << name
		end
		fac_pic = faculty.sample(2)
		fac_caption[0] = File.read("#{HOME}/html/faculty/#{fac_pic[0]}.txt")
		fac_caption[1] = File.read("#{HOME}/html/faculty/#{fac_pic[1]}.txt")

		f.puts "<div class='todaytitle'>UCHICAGO PHYSICS</div>"
		f.puts "<div id=\"physicsCarousel\" class='carousel slide carousel-fade' data-ride='carousel' data-interval='30000'>"
		f.puts "<div class='carousel-inner'>"
		f.puts "<div class='item active'><img src=\"#{pic_url}\" alt='Physicists in Action' class='img-responsive' /><p>If you can tell us anything about this picture, plea
se email maryh@hep.uchicago.edu about image ##{pic_id}.</p></div>"
		f.puts "<div class='item'><img src=\"\/faculty\/#{fac_pic[0]}.jpg\" alt='#{fac_pic}' class='img-responsive' /><p>#{fac_caption[0]}</p></div>"
		f.puts "<div class='item'><img src=\"#{hist_url}\" alt='historical picture' class='img-responsive' /><p>#{hist_caption}</p></div>"
		f.puts "<div class='item'><img src=\"\/faculty\/#{fac_pic[1]}.jpg\" alt='#{fac_pic}' class='img-responsive' /><p>#{fac_caption[1]}</p></div>"
		f.puts "</div>"
		f.puts "</div>"
	else
		sorted = events.sort_by { |x| x[:start] }

		f.puts "<div class='todaytitle'>TODAY'S EVENTS</div>"
		sorted.each do |event|
			if (event[:start].strftime("%-l:%M %p") == "12:00 AM")
				f.puts "<span class='left'>All Day</span><span class='right'>#{event[:location]}</span>"
				f.puts "#{event[:summary]}"
				f.puts "<hr />"
			else
				f.puts "<span class='left'>#{event[:start].strftime("%-l:%M %p")}</span><span class='right'>#{event[:location]}</span>"
				f.puts "#{event[:summary]}"
				f.puts "<hr />"
			end
		end
	end
end

open('upcoming.html','w') do |f|
	sorted = upcoming.sort_by { |x| x[:start] }
	f.puts "<div class='todaytitle'>UPCOMING EVENTS</div>"
	sorted.each do |event|
		f.puts "<div class='timeroom'>"
		if (event[:start].strftime("%-l:%M %p") == "12:00 AM")
			f.puts "<span class='left'>#{event[:start].strftime("%A, %B %-d, All Day")}</span><span class='right'>#{event[:location]}</span>"
		else
			f.puts "<span class='left'>#{event[:start].strftime("%A, %B %-d at %-l:%M %p")}</span><span class='right'>#{event[:location]}</span>"
		end
		f.puts "</div>"
		f.puts "<div class='summary'>#{event[:summary]}</div>"
		f.puts "<hr />"
	end
	f.puts "</div>"
end

