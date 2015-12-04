require 'json'

module SlackUtil
	def SlackUtil.get_json(url)
		uri = URI.parse(url)
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		response = http.get(uri.request_uri)
		return JSON.parse(response.body)
	end

	def SlackUtil.get_current_user(token)
		return get_json("https://slack.com/api/auth.test?token=#{token}")['user_id']
	end

	def SlackUtil.get_all_users(token)
		return get_json("https://slack.com/api/users.list?token=#{TOKEN}")['members']
	end
end