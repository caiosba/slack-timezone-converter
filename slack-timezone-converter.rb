require 'rubygems'
require 'bundler/setup'
require 'active_support/time'
require 'json'
require 'logger'
require_relative 'slack_util'
require_relative 'timezone_adjuster'
Bundler.require

$log = Logger.new(STDOUT)

TOKEN = ARGV[0] || ENV['TOKEN'] # Get one at https://api.slack.com/web#basics
PER_LINE = ARGV[1] || 1         # Number of times per line
MESSAGE = ARGV[2].to_s          # Additional message to be appended

# Get the current user from token

slack_util = SlackUtil.new(token: TOKEN)
CURRENT_USER = slack_util.get_current_user()

# Get users list and set default timezone
users = {}

slack_util.get_all_users().each do |user|
  offset, user_tz, alt_tz_label = user['tz_offset'], user['tz'], user['tz_label']

  # Bots don't have `tz` set for some reason, but they do have `tz_label` set and it
  # will (probably) be in the Pacific TZ
  if user['is_bot'] and not alt_tz_label.nil? and alt_tz_label.start_with?('Pacific')
    user_tz = 'America/Los_Angeles'
  end

  next if offset.nil? or user_tz.nil? or user['deleted']

  # Offsets are expressed in seconds for some reason
  offset /= 3600
  users[user['id']] = { offset: offset, tz: ActiveSupport::TimeZone[offset].tzinfo.name }
end

Time.zone = users[CURRENT_USER][:tz]

# Connect to Slack

url = SlackRTM.get_url token: TOKEN 
client = SlackRTM::Client.new websocket_url: url
adjuster = TimezoneAdjuster.new(token: TOKEN, prepended_message: MESSAGE, per_line: PER_LINE)

# Listen for new messages (events of type "message")

$log.info "Connected to Slack"

client.on :message do |data|
  message_text = adjuster.get_times_for(users: users, data: data)
  if !message_text.nil?
    $log.debug "Sending message: #{message_text}"
    begin
      client.send({ type: 'message', channel: data['channel'], text: message_text })
    rescue
      # Just ignore the message
      $log.error "Death sending that message."
    end
  end
end

# Runs forever until an exception happens or the process is stopped/killed

client.main_loop
assert false
