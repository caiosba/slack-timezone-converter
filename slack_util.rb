require 'json'

module SlackUtil
	def SlackUtil.CurrentUser(token)
		uri = URI.parse("https://slack.com/api/auth.test?token=#{token}")
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		response = http.get(uri.request_uri)
		return JSON.parse(response.body)['user_id']
	end

	def SlackUtil.AllUsers(token)
		uri = URI.parse("https://slack.com/api/users.list?token=#{TOKEN}")
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		response = http.get(uri.request_uri)
		return JSON.parse(response.body)['members']
	end
end