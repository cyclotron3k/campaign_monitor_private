require 'campaign_monitor_private/version'
require 'mechanize'
require 'uri'
require 'rotp'

class CampaignMonitorPrivate
	class Error < StandardError; end

	def initialize(
		username:   ENV['CAMPAIGN_MONITOR_USERNAME'],
		password:   ENV['CAMPAIGN_MONITOR_PASSWORD'],
		tfa_token:  ENV['CAMPAIGN_MONITOR_2FA'],
		tfa_secret: ENV['CAMPAIGN_MONITOR_SECRET'],
		domain:     ENV['CAMPAIGN_MONITOR_DOMAIN'],
		default_customer: ENV['CAMPAIGN_MONITOR_DEFAULT_CUSTOMER']
	)

		raise ArgumentError, 'No username provided' unless username
		raise ArgumentError, 'No password provided' unless password

		@logged_in        = false
		@username         = username
		@password         = password
		@tfa_token        = tfa_token
		@totp             = tfa_secret ? ROTP::TOTP.new(tfa_secret) : nil
		@domain           = domain
		@default_customer = default_customer

		@active_customer  = nil
		@list_cache       = {}
		@segment_cache    = {}
		@superuser        = false
	end

	class JsonParser < Mechanize::Page
		attr_reader :json
		def initialize(uri=nil, response=nil, body=nil, code=nil)
			@json = JSON.parse body
			super uri, response, body, code
		end
	end

	def agent
		@agent ||= Mechanize.new do |a|
			a.user_agent = "Campaign Monitor Client/#{VERSION}"
			a.pluggable_parser['application/json'] = JsonParser
			a.max_history = 1
		end
	end

	def login
		login_without_domain if @domain.nil?
		login_with_domain
	end

	def set_active_customer(customer_name=@default_customer)
		login unless @logged_in

		# only superusers need to set the active customer
		return true unless @superuser

		raise Error, "customer_name required" if customer_name.nil?

		return if @active_customer == customer_name

		link = nil
		counter = 0
		loop do
			link = agent.page.link_with(
				text: /\A\s*#{customer_name}\s*\z/,
				href: /\/\?ID=[\h]+\b/
			)
			break if link
			raise Error, "Can't find #{customer_name}" if counter >= 1
			uri = URI "https://#{@domain}.createsend.com/admin/"
			agent.get uri
			counter += 1
		end

		response = agent.click link

		raise Error, "Invalid response code: #{response.code}" unless response.code == '200'
		@active_customer = customer_name
	end

	def get_list_id_for(list_name)
		set_active_customer unless @active_customer

		return @list_cache[@active_customer][list_name] if @list_cache.key? @active_customer

		if agent.page.uri.to_s != "https://#{@domain}.createsend.com/subscribers/"
			agent.get "https://#{@domain}.createsend.com/subscribers/"
		end

		@list_cache[@active_customer] = agent.page.links_with(
			href: /listDetail\.aspx\?listID=[\h]+\b/
		).each_with_object({}) do |link, obj|
			obj[link.text] = link.href[/[\h]+\z/]
		end

		@list_cache[@active_customer][list_name]

	end

	def get_segments_for(list_id)
		login unless @logged_in

		# @active_customer is not required!!

		return @segment_cache[list_id] if @segment_cache.key? list_id

		uri = URI "https://#{@domain}.createsend.com/subscribers/api/#{list_id}/segments"
		response = agent.get uri
		raise Error, "Invalid response code: #{response.code}" unless response.code == '200'
		@segment_cache[list_id] = response.json["segments"]
	end

	private

	def login_without_domain
		uri = URI 'https://login.createsend.com/l'

		response = agent.get(uri).form_with(
			method: 'POST',
			action: '/l'
		) do |form|
			form.username      = @username
			form.password      = @password
			if @tfa_token
				form.authenticator = @tfa_token
			elsif @totp
				form.authenticator = @totp.now
			end
		end.submit

		raise Error, "Login error" if response.code != '200'

		# response.json = {
		# 	"MultipleAccounts"               => false,
		# 	"LoginStatus"                    => "Success",
		# 	"SiteAddress"                    => "https://acme.createsend.com",
		# 	"ErrorMessage"                   => "",
		# 	"SessionExpired"                 => false,
		# 	"Url"                            => "https://acme.createsend.com/login?Origin=Marketing",
		# 	"DomainSwitchAddress"            => "https://acme.createsend.com",
		# 	"DomainSwitchAddressQueryString" => nil,
		# 	"NeedsDomainSwitch"              => false
		# }

		if response.json.key? 'DomainSwitchAddress'
			dsa = response.json['DomainSwitchAddress']
			raise Error, "Cross domain: #{dsa}" unless /\.createsend\.com\z/ === dsa
			@domain = URI(dsa).host.split('.', 2).first
		else
			raise Error, "Couldn't determine subdomain"
		end

		true
	end

	def login_with_domain
		raise Error, 'No subdomain specified' unless @domain

		uri = URI "https://#{@domain}.createsend.com/login"

		response = agent.get(uri).form_with(
			method: 'POST',
			action: '/login'
		) do |form|
			form.username      = @username
			form.password      = @password
			if @tfa_token
				form.authenticator = @tfa_token
			elsif @totp
				form.authenticator = @totp.now
			end
		end.submit

		raise Error, "Login error" if response.code != '200'

		superuser_check

		@logged_in = true
	end

	def superuser_check
		@superuser = !agent.page.link_with(text: /Clients/, href: '/admin/clients/').nil?
	end

end
