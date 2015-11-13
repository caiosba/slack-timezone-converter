require 'rubygems'
require 'bundler/setup'
require 'active_support/all'
require 'json'
require 'logger'
require_relative 'slack_util'
require_relative 'timezone_adjuster'
Bundler.require

log = Logger.new(STDOUT)

TOKEN = ARGV[0]         # Get one at https://api.slack.com/web#basics
PER_LINE = ARGV[1] || 1 # Number of times per line
MESSAGE = ARGV[2].to_s  # Additional message to be appended

# Get the current user from token

CURRENT_USER = SlackUtil.CurrentUser(TOKEN)

# Get users list and all available timezones and set default timezone

timezones = {}
users = {}

SlackUtil.AllUsers(TOKEN).each do |user|
  offset, label = user['tz_offset'], user['tz']
  next if offset.nil? or offset == 0 or label.nil? or user['deleted']
  label = ActiveSupport::TimeZone.find_tzinfo(label).current_period.abbreviation.to_s
  offset /= 3600
  if key = timezones.key(offset) and !key.split(' / ').include?(label)
    timezones.delete(key)
    label = key + ' / ' + label
  end
  timezones[label] = offset unless timezones.has_value?(offset)
  users[user['id']] = { offset: offset, tz: ActiveSupport::TimeZone[offset].tzinfo.name }
end

timezones = timezones.sort_by{ |key, value| value }

Time.zone = users[CURRENT_USER][:tz]

# Connect to Slack

url = SlackRTM.get_url token: TOKEN 
client = SlackRTM::Client.new websocket_url: url
adjuster = TimezoneAdjuster.new(CURRENT_USER, timezones, MESSAGE)

# Listen for new messages (events of type "message")

log.info("Connected to Slack")

client.on :message do |data|
  message_text = adjuster.get_list_for(users, data)
  if !message_text.nil?
    log.debug("Sending message: #{message_text}")
    begin
      client.send({ type: 'message', channel: data['channel'], text: message_text })
    rescue
      # Just ignore the message
      log.error("Death sending that message.")
    end
  end
end

# Runs forever until an exception happens or the process is stopped/killed

client.main_loop
assert false
