# AnPostReturn

A Ruby gem for integrating with An Post's return label generation service. This gem provides a simple interface for creating return labels for domestic, EU, and non-EU returns through An Post's SFTP service.

## Features

- Generate return labels for domestic, EU, and non-EU returns
- SFTP integration for secure file transfer
- Simple configuration options
- Robust error handling
- Comprehensive tracking data parsing

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'an_post_return'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install an_post_return
```

## Configuration

Configure the gem with your An Post credentials:

```ruby
AnPostReturn.configure do |config|
  # SFTP Configuration (required)
  config.sftp_config = {
    host: 'your_sftp_host',
    username: 'your_username',
    password: 'your_password',
    remote_path: '/path/to/remote/files'
  }

  # Optional proxy configuration
  config.proxy_config = {
    host: 'proxy-host',
    port: 'proxy-port',
    user: 'proxy-user',
    password: 'proxy-password'
  }

  # Environment setting
  config.test = false # Set to true for sandbox environment
end
```

## Usage

### Creating a Return Label

```ruby
# Initialize a new return label request
label = AnPostReturn::ReturnLabel.create(
  # Required parameters
  contract_number: "123456",
  product_code: "DOM",
  weight: 1.5,

  # Address details
  from_address: {
    name: "Sender Name",
    address_line_1: "123 Sender Street",
    city: "Dublin",
    county: "Dublin",
    postcode: "D01 F5P2",
    country: "IE"
  },
  to_address: {
    name: "Recipient Name",
    address_line_1: "456 Recipient Road",
    city: "Cork",
    county: "Cork",
    postcode: "T12 RX8C",
    country: "IE"
  }
)

# Access the label details
puts label.tracking_number
puts label.label_url
```

### Tracking Shipments

```ruby
tracker = AnPostReturn::Tracker.new

# Track by account number (gets all files)
tracker.track_with_account_number("3795540") do |file, data|
  puts "Processing file: #{file}"
  puts "Tracking data: #{data}"
end

# Track by account number (gets the last 2 files)
tracker.track_with_account_number("3795540", last: 2) do |file, data|
  puts "Processing file: #{file}"
  puts "Tracking data: #{data}"
end

# Track from a specific file onwards, by increment file name by 1 until no file is found
tracker.track_from("cdt0370132115864.txt") do |file, data|
  puts "Processing file: #{file}"
  puts "Tracking data: #{data}"
end
```

The tracking data will contain:

- `:header` - File header information
- `:data` - Array of tracking events
- `:footer` - File footer information

Possible tracking statuses: "SORTED", "ATTEMPTED DELIVERY", "DELIVERED", "ITEM ON HAND", "PRE-ADVICE", "OUT FOR DELIVERY", "ITEM ACCEPTED", "CUSTOMER INSTRUCTION REC"

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/PostCo/an_post_return. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/PostCo/an_post_return/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AnPostReturn project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/PostCo/an_post_return/blob/main/CODE_OF_CONDUCT.md).
