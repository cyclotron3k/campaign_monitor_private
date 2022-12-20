# CampaignMonitorPrivate

> **ARCHIVED** This repo has been archived since Campaign Monitor changed their log-in process to depend on JavaScript. Mechanize doesn't execute JavaScript, so a complete rewrite with something a lot more heavyweight (e.g. Selenium) would be necessary.

The Campaign Monitor website and the Campaign Monitor API use entirely independent IDs to reference your data. This gem helps reconcile the two worlds.

This software is an unofficial client for the private Campaign Monitor API, and is not endorsed by Campaign Monitor. Future updates to Campaign Monitor's website could possibly break the functionality of this library without warning.

Please read this whole document before using this gem, especially the sections on **Stability** and **Security and Permissions**

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'campaign_monitor_private'
```

Or run `gem install campaign_monitor_private` on your command line and add `require 'campaign_monitor_private'` to your code.

## Usage

There are a number of ways to instantiate `CampaignMonitorPrivate`:

```ruby
client = CampaignMonitorPrivate.new(
  username:  'emailaddress@acme.com',
  password:  'blahblahblah'
)
```

This is the most basic way to log in. It will log into Campaign Monitor's main site, which will then bounce you to your custom subdomain and it will then log in again. To avoid this double login, you can (and should) provide the subdomain:

```ruby
client = CampaignMonitorPrivate.new(
  username: 'emailaddress@acme.com',
  password: 'blahblahblah',
  domain:   'acme'
)
```

This will halve the login time.

This gem is able to handle privileged (superuser) accounts and non-privileged accounts. I'd strongly recommend setting up unprivileged accounts for use with this gem. But if you insist on using a superuser account, you will need to name the subaccount you want to work with. There are two ways to do this.

At instantiation:
```ruby
client = CampaignMonitorPrivate.new(
  username: 'superuser@acme.com',
  password: 'blahblahblah',
  domain:   'acme'
  default_customer: 'Some Customer'
)
```

Or during runtime:
```ruby
client = CampaignMonitorPrivate.new(
  username: 'superuser@acme.com',
  password: 'blahblahblah',
  domain:   'acme'
)

client.set_active_customer "Customer One"

# ...

client.set_active_customer "Customer Two"

# ...
```


## Two Factor Auth
The gem is capable of handling Two Factor Auth, in two ways:

If you know your 2FA secret and want `CampaignMonitorPrivate` to automatically generate the tokens for you:
```ruby
client = CampaignMonitorPrivate.new(
  username:   'user@acme.com',
  password:   'blahblahblah',
  tfa_secret: 'BCFTP3LNOYIK5O6E1F02KMYTT5A86BCC43UQHWCOYWT8L'
)
```

Or if you want to manually provide OTP tokens:
```ruby
my_token = '123456'

client = CampaignMonitorPrivate.new(
  username:  'user@acme.com',
  password:  'blahblahblah',
  tfa_token: my_token
)
```

**NOTE:** The client will not attempt login until you try to retrieve data from Campaign Monitor. So if you instantiate `CampaignMonitorPrivate` with a 2FA token, but then don't use it for some time; the token may have expired. To avoid this scenario, you can call `client.login` immediately after instantiation to force login.

There should be no scenario where you're providing a token and a secret, but if you do, the token will be used and `CampaignMonitorPrivate` will not try to generate one for you using the secret.

## Environment Variables

All of the above can be provided via environment variables:
```ruby
username:   ENV['CAMPAIGN_MONITOR_USERNAME'],
password:   ENV['CAMPAIGN_MONITOR_PASSWORD'],
tfa_token:  ENV['CAMPAIGN_MONITOR_2FA'],
tfa_secret: ENV['CAMPAIGN_MONITOR_SECRET'],
domain:     ENV['CAMPAIGN_MONITOR_DOMAIN'],
default_customer: ENV['CAMPAIGN_MONITOR_DEFAULT_CUSTOMER']
```

## Getting IDs

That's why we're all here, of course.

```ruby
list_id = client.get_list_id_for 'Main List'
# => '164bfaa483d3382b'

segments = client.get_segments_for list_id
# => [{"id"=>"B8C33EE6D6DA33F2",
#   "name"=>"18 people",
#   "systemSegmentType"=>"None",
#   "subscriberCount"=>18,
#   "lastUpdated"=>"2/08/2019 11:41:00 AM",
#   "integrationType"=>[],
#   "advancedSegmentId"=>nil,
#   "isBehavioural"=>false},
#  {"id"=>"E6B17AFF15A93EA9",
#   "name"=>"Newsletter Subscribers",
#   "systemSegmentType"=>"None",
#   "subscriberCount"=>36927348,
#   "lastUpdated"=>"12/03/2015 11:41:00 AM",
#   "integrationType"=>[],
#   "advancedSegmentId"=>nil,
#   "isBehavioural"=>false},
#  {"id"=>"2A0C22D45159D1FF",
#   "name"=>"Example Targeting Segment",
#   "systemSegmentType"=>"None",
#   "subscriberCount"=>1,
#   "lastUpdated"=>"2/08/2019 11:41:00 AM",
#   "integrationType"=>[],
#   "advancedSegmentId"=>nil,
#   "isBehavioural"=>false}]
```

**NOTE:** The results are cached internally, so watch out for that.

## Stability

This gem makes use of the dark arts of screen scraping. This means that it could break at any moment. It has been built to be as robust as possible, but there's no guarantee that it's going to work tomorrow. Bear this in mind, and don't rely on it for anything important.

## Security and Permissions

Although this gem supports 2FA, using 2FA doesn't provide much additional security if you're storing your 2FA secret alongside your username and password as you still only have one factor. To get your 2FA secret, you'll need to enable 2FA in Campaign Monitor and extract the secret from the QR code you're presented with. You may also be able to extract the secret from whatever authentication app you're using on your phone.

Although this gem can work with superuser accounts (accounts responsible for managing a number of sub-accounts), unless you really need to use a superuser account, it's a much better idea to set up per-customer accounts, and lock-down their permissions. **The only permission you need is "Lists & Subscribers"**

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cyclotron3k/campaign_monitor_private. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the CampaignMonitorPrivate project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/cyclotron3k/campaign_monitor_private/blob/master/CODE_OF_CONDUCT.md).
