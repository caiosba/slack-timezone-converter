require 'rubygems'
require 'bundler/setup'
require 'active_support/all'
require 'json'
Bundler.require

TOKEN = ARGV[0]         # Get one at https://api.slack.com/web#basics
PER_LINE = ARGV[1] || 1 # Number of times per line
MESSAGE = ARGV[2].to_s  # Additional message to be appended

# Get a Slack clock emoji from a time object

def slack_clock_emoji_from_time(time)
  hour = time.hour % 12
  hour = 12 if hour == 0
  time.min==30? ":clock#{hour}30:" : ":clock#{hour}:"
end

# Normalize times

def normalize(text)
  text.gsub(/([0-9]{1,2})([0-9]{2})( ?([aA]|[pP])[mM])/, '\1:\2\3')
end

# Get the current user from token

uri = URI.parse("https://slack.com/api/auth.test?token=#{TOKEN}")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
response = http.get(uri.request_uri)
CURRENT_USER = JSON.parse(response.body)['user_id']

# Get users list and all available timezones and set default timezone

uri = URI.parse("https://slack.com/api/users.list?token=#{TOKEN}")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
response = http.get(uri.request_uri)
timezones = {}
users = {}
JSON.parse(response.body)['members'].each do |user|
  offset, label = user['tz_offset'], user['tz']
  next if offset.nil? or offset == 0 or label.nil? or user['deleted']
  label = ActiveSupport::TimeZone.find_tzinfo(label).current_period.abbreviation.to_s
  if key = timezones.key(offset) and !key.split(' / ').include?(label)
    timezones.delete(key)
    label = key + ' / ' + label
  end
  timezones[label] = offset unless timezones.has_value?(offset)
  users[user['id']] = { offset: offset, tz: ActiveSupport::TimeZone[offset].tzinfo.name }
end

timezones = timezones.sort_by{ |key, value| value }

#Time.zone = users[CURRENT_USER][:tz]

# Connect to Slack

url = SlackRTM.get_url token: TOKEN 
client = SlackRTM::Client.new websocket_url: url

# Listen for new messages (events of type "message")

puts "[#{Time.now}] Connected to Slack!"

client.on :message do |data|
  if data['type'] === 'message' and !data['text'].nil? and data['subtype'].nil? and data['reply_to'].nil? and (data['text'].include?("@time") or data['text'].include?("@U03N0KXMD") or data['text'].include?("@timebot") or data['text'].include?("@U5D0ARDSS")) and
     !data['text'].gsub(/<[^>]+>/, '').match(/[0-9](([hH]([0123456789 ?:,;.]|$))|( ?[aA][mM])|( ?[pP][mM])|(:[0-9]{2}))/).nil?
    
    # Identify time patterns
    begin
      Time.zone = begin users[data['user']][:tz] rescue users[CURRENT_USER][:tz] end
      text = normalize data['text']
      time = Time.zone.parse(text).utc
      puts "[#{Time.now}] Got time #{time}"

      text = []
      i = 0
      timezones.each do |label, offset|
        i += 1
        localtime = time + offset
        emoji = slack_clock_emoji_from_time(localtime)
        message = "#{emoji} #{localtime.strftime('%H:%M')} #{label}"
        message += (i % PER_LINE.to_i == 0) ? "\n" : " "
        text << (users[data['user']] && offset == users[data['user']][:offset] ? "#{message}" : message)
      end

      text << (MESSAGE % time.to_i.to_s)

      puts "[#{Time.now}] Sending message..."
      client.send({ type: 'message', channel: data['channel'], text: text.join })
    rescue Exception => e
      # Just ignore the message
      puts "Exception: #{e.message}"
    end
  end
end

# Runs forever until an exception happens or the process is stopped/killed

client.main_loop
assert false
