lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'campaign_monitor_private/version'

Gem::Specification.new do |spec|
	spec.name        = 'campaign_monitor_private'
	spec.version     = CampaignMonitorPrivate::VERSION
	spec.authors     = ['cyclotron3k']
	spec.email       = ['aidan.samuel@gmail.com']

	spec.summary     = 'A screen-scraper to retrieve vital information not available via the public API'
	spec.homepage    = 'https://github.com/cyclotron3k/campaign_monitor_private'
	spec.license     = 'MIT'

	spec.metadata    = {
		'bug_tracker_uri'   => 'https://github.com/cyclotron3k/campaign_monitor_private/issues',
		'changelog_uri'     => 'https://github.com/cyclotron3k/campaign_monitor_private/blob/master/CHANGELOG.md',
		'documentation_uri' => "https://github.com/cyclotron3k/campaign_monitor_private/blob/v#{CampaignMonitorPrivate::VERSION}/README.md",
		'source_code_uri'   => 'https://github.com/cyclotron3k/campaign_monitor_private'
	}

	spec.require_paths = ['lib']
	spec.files         = Dir.chdir(File.expand_path(__dir__)) do
		`git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
	end

	spec.add_runtime_dependency 'mechanize', '~> 2.7'
	spec.add_runtime_dependency 'rotp', '~> 5.0'

	spec.add_development_dependency 'bundler', '~> 1.17'
	spec.add_development_dependency 'bundler-audit', '~> 0.6'
	spec.add_development_dependency 'minitest', '~> 5.0'
	spec.add_development_dependency 'pry', '~> 0.12'
	spec.add_development_dependency 'rake', '~> 10.0'
	# spec.add_development_dependency 'webmock', '~> 3.5'

	spec.required_ruby_version = '~> 2.3'
end
