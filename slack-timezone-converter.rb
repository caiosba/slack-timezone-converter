require 'rubygems'
require 'bundler/setup'
require 'date'
require 'json'
Bundler.require

# Currently supported formats: 10am 10 am 10 AM 10AM 10pm 10PM 10 pm 10 PM 10h 10H 10h30 10H30 10:30 (with or without leading zeros)

TOKEN = ARGV.first                                                          # Get one at https://api.slack.com/web#basics
DEFAULT_TIMEZONE = ARGV.last                                                # Any supported string, like 'PST' for example
TIME_PATTERN = /(([0-2]?[0-9][:hH][0-5]?[0-9]?)|([0-9][0-9]? ?[aApP][mM]))/ # Which time formats we are able to parse

# Function to convert from a time offset (like '-3') to a valid offset string (like '-03:00')

def offset_int2str(int)
  str = ''
  str += (int < 0 ? '-' : '+')
  str += '0' if int.abs < 10
  str += int.abs.to_s
  str + ':00'
end

# Get a Slack clock emoji from a time object

def slack_clock_emoji_from_time(time)
  hour = time.hour % 12
  hour = 12 if hour == 0
  ":clock#{hour}:"
end

# Parse text and looks for time patterns

def parse(text)
  matches = []
  text.scan(TIME_PATTERN).each do |match|
    time = match.first.gsub(/[hH]([0-9][0-9])/, ':\1').gsub(/[hH]/, '')
    unless (time =~ /[aApP][mM]/).nil?
      time = time.gsub(/[^0-9]+/, '').to_i
      time += 12 if !(match.first =~ /[pP][mM]/).nil? and time < 12
      time = 0 if !(match.first =~ /[aA][mM]/).nil? and time == 12
      time = time.to_s + ':00'
    end
    matches << time + ':00'
  end
  matches
end

# Get users list and all available timezones

uri = URI.parse("https://slack.com/api/users.list?token=#{TOKEN}")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
response = http.get(uri.request_uri)
timezones = {}
JSON.parse(response.body)['members'].each do |user|
  offset, label = user['tz_offset'], user['tz_label']
  next if offset.nil? or offset == 0 or label.nil?
  timezones[label] = offset / 3600 unless timezones.has_key?(label)
end

# Connect to Slack

url = SlackRTM.get_url token: TOKEN 
client = SlackRTM::Client.new websocket_url: url

# Listen for new messages (events of type "message")

puts "[#{Time.now}] Connected to Slack!"

client.on :message do |data|
  if data['type'] === 'message' and !data['text'].nil? and data['subtype'].nil? and data['reply_to'].nil?
    
    # Identify time patterns
    matches = parse(data['text'])
    matches.each do |match|
      begin
        timestr = "2015-01-01 #{match} #{DEFAULT_TIMEZONE}"
        puts "[#{Time.now}] Got time #{timestr}"
        time = DateTime.parse(timestr)

        text = []
        timezones.each do |label, offset|
          zone = offset_int2str(offset)
          localtime = time.new_offset(zone)
          emoji = slack_clock_emoji_from_time(localtime)
          text << "#{emoji} *#{localtime.strftime('%H:%M')}* `(#{label})`\n"
        end

        puts "[#{Time.now}] Sending message..."
        client.send({ type: 'message', channel: data['channel'], text: text.join })
      rescue
        puts "[#{Time.now}] Invalid date"
      end
    end
  end
end

# Runs forever until an exception happens or the process is stopped/killed

client.main_loop
assert false
