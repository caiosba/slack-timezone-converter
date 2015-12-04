require 'json'

class SlackUtil
	def initialize(token:)
		@token = token
	end

	def get_json(endpoint, additional_queries: '')
		uri = URI.parse("https://slack.com/api/#{endpoint}?token=#{@token}#{additional_queries}")
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		response = http.get(uri.request_uri)
		return JSON.parse(response.body)
	end

	def get_current_user()
		return get_json("auth.test")['user_id']
	end

	def get_all_users()
		return get_json("users.list")['members']
	end

	def get_channel(channel)
		return get_json("channels.info", additional_queries: "&channel=#{channel}")['channel']
	end

	def get_user(user)
		return get_json("users.info", additional_queries: "&user=#{user}")['user']
	end
end