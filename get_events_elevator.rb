#!/usr/bin/ruby
require 'google/apis/calendar_v3'
require 'yaml'
require 'date'

HOME="/var/www"
SAMPLES = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]

#Google::Apis.logger.level = Logger::DEBUG

# Get config info
config = YAML.load_file("#{HOME}/scripts/config/config.yml")

calendar = Google::Apis::CalendarV3::CalendarService.new
calendar.key = config['apikey']
calendarids = config['calendars']

# Get today & tomorrow which is used for the range 

# Get range of dates for which we want to get events
localtime = Time.now.getlocal
today = localtime.to_date
last_upcoming_event_date = today + 8
start_of_day = DateTime.parse(localtime.strftime("%Y-%m-%dT00:00:00%z"))
end_of_day = DateTime.parse(localtime.strftime("%Y-%m-%dT23:59:59%z"))
last_upcoming_event = DateTime.parse(last_upcoming_event_date.strftime("%Y-%m-%dT23:59:59%z"))

events = Array.new

calendarids.each do |name, id|
	entries = calendar.list_events(id,
		single_events: true,
		time_min: start_of_day.rfc3339,
		time_max: last_upcoming_event.to_datetime.rfc3339
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
end

open("#{HOME}/html/events.html",'w') do |f|
	sorted = events.sort_by { |x| x[:start] }
	f.puts "<div class='todaytitle'>EVENTS</div>"
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

# Now write the research.html file with info
sites = File.readlines("#{HOME}/scripts/research-sites.txt")
open("#{HOME}/html/research.html","w") do |f|
  f.print "<div class='physicsCarousel' class='carousel slide' data-ride='carousel' data-interval='25000'>\n"
  f.print "  <div class='carousel-inner'>\n"
  sites.each_with_index do |site,index|
    url = site.chomp
    if (index == 0)
	f.print "<div class='item active'><img src='#{url}' class='slideshow img-responsive' width='100%'/></div>\n"
    else
	f.print "<div class='item'><img src='#{url}?#{SAMPLES.sample}' class='slideshow img-responsive' width='100%'/></div>\n"
    end
  end
  f.print "</div>\n"
  f.print "</div>\n"
end
