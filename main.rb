require 'httparty'
require 'pry'
require 'icalendar'

require_relative './fetcher'

File.write('db.json', '{}') unless File.exist?('db.json')
local_db = JSON.parse(File.read('db.json'))

Fetcher.new.fetch.each_with_object(local_db) do |event, db|
  db[event['id'].to_s] = event
end

File.write('db.json', local_db.to_json)

cal = Icalendar::Calendar.new

cal.refresh_interval = 'DURATION:PT12H'

local_db.each_value do |event|
  event['streams']&.each_with_index do |stream, i|
    cal.event do |e|
      e.dtstart = Icalendar::Values::DateTime.new(Time.parse(stream['startAt']))
      e.dtend = Icalendar::Values::DateTime.new(Time.parse(stream['endAt']))
      e.summary = stream['title']
      e.description = "Day #{i + 1} of #{event['name']}"
      e.location = stream['type']
    end
  end
end

File.open('events.ical', 'w') { |f| f.write cal.to_ical }
