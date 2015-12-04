require 'active_support/time'
require_relative 'slack_util'

class TimezoneAdjuster
	def initialize(token:, prepended_message: '', per_line: 1)
		@prepended_message = prepended_message
		@per_line = per_line
		@channels = {}
		@slack_util = SlackUtil.new(token: token)
	end

	# Get a Slack clock emoji from a time object
	def slack_clock_emoji_from_time(time)
	  hour = time.hour % 12
	  hour = 12 if hour == 0
	  ":clock#{hour}:"
	end

	# Normalize times
	def normalize(text)
	  text.gsub(/([0-9]{1,2})([0-9]{2})( ?([aA]|[pP])[mM])/, '\1:\2\3')
	end

	def has_time?(text)
		return !text.gsub(/<[^>]+>/, '').match(/[0-9](([hH]([0123456789 ?:,;.]|$))|( ?[aA][mM])|( ?[pP][mM])|([.:][0-9]{2}))/).nil?
	end

	def get_times_for(users:, data:)
  		dataType = data['type']
		dataText = data['text']
  		if dataType != 'message' or dataText.nil? or not data['subtype'].nil? or not data['reply_to'].nil? or not has_time? dataText
  			return nil
  		end

  		dataUser = data['user']
	    dataChannel = data['channel']

		if @channels[dataChannel].nil?
			channel = @slack_util.get_channel(dataChannel)

			if channel.nil?
				return "I don't really work that way."
			end

			channelTZs = {}
			channel['members'].each do |userId|
				user = @slack_util.get_user(userId)
				offset, label = user['tz_offset'], user['tz']
				next if offset.nil? or label.nil? or user['deleted'] or user['is_bot']
				label = ActiveSupport::TimeZone.find_tzinfo(label).current_period.abbreviation.to_s
				offset /= 3600
				if key = channelTZs.key(offset) and !key.split(' / ').include?(label)
				  channelTZs.delete(key)
				  label = key + ' / ' + label
				end
				channelTZs[label] = offset unless channelTZs.has_value?(offset)
			end
			@channels[dataChannel] = channelTZs.sort_by{ |key, value| value }
		end

		# Identify time patterns
		begin
			Time.zone = users[data['user']][:tz]
			text = normalize data['text']
			time = Time.zone.parse(text).utc
			$log.debug "[#{Time.now}] Got time #{time}"

			text = []
			i = 0
			@channels[dataChannel].each do |label, offset|
				i += 1
				localtime = time + offset.to_i.hours
				emoji = slack_clock_emoji_from_time(localtime)
				message = "#{emoji} #{localtime.strftime('%H:%M')} #{label}"
				message += (i % @per_line.to_i == 0) ? "\n" : " "
				text << (offset == users[data['user']][:offset] ? "#{message}" : message)
			end

			text << (@prepended_message % time.to_i.to_s)

			return text.join
		rescue Exception => e
			$log.error e
			return nil
		end
	end
end