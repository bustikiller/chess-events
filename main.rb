# frozen_string_literal: true

require 'httparty'
require 'pry'
require 'icalendar'
require 'active_support/core_ext'

require_relative './fetcher'
require_relative './stream_url_builder'

UUID_NAMESPACE = '98aacae8-1521-434e-8f29-a619b963de2c'
TZID = 'UTC'

File.write('db.json', '{}') unless File.exist?('db.json')
local_db = JSON.parse(File.read('db.json'))

Fetcher.new.fetch.each_with_object(local_db) do |event, db|
  uuid = Digest::UUID.uuid_v5(UUID_NAMESPACE, event['id'].to_s)

  db_event = db[event['id'].to_s]
  changed = db_event.nil? || db_event['updatedAt'].nil? || db_event.except('updatedAt', 'uuid') != event

  db[event['id'].to_s] = event.merge(
    'uuid' => uuid,
    'updatedAt' => (changed ? Time.now.utc : Time.parse(db_event['updatedAt']))
  )
end

File.write('db.json', local_db.to_json)

cal = Icalendar::Calendar.new

cal.refresh_interval = 'DURATION:PT12H'

JSON.parse(File.read('db.json')).each_value do |event|
  event['streams']&.each_with_index do |stream, i|
    next unless stream.dig('language', 'locale').start_with?('en_')

    cal.event do |e|
      e.uid = Digest::UUID.uuid_v5(UUID_NAMESPACE, event['uuid'] + i.to_s)
      e.dtstart = Icalendar::Values::DateTime.new(Time.parse(stream['startAt']), 'tzid' => TZID)
      e.dtend = Icalendar::Values::DateTime.new(Time.parse(stream['endAt']), 'tzid' => TZID)
      e.dtstamp = Icalendar::Values::DateTime.new(Time.parse(event['updatedAt']))
      e.summary = stream['title']
      e.description = "Day #{i + 1} of #{event['name']}"
      e.url = e.location = StreamUrlBuilder.build(stream['type'], stream['channel'])
    end
  end
end

File.open('events.ical', 'w') { |f| f.write cal.to_ical }
