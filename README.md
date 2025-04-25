# AnPostReturn

A Ruby gem for integrating with An Post's return label generation and tracking service. This gem provides a simple interface for creating return labels for domestic, EU, and non-EU returns, and tracking through An Post's SFTP service.

## Features

- Generate return labels for domestic, EU, and non-EU returns
- SFTP integration for secure file transfer
- Simple configuration options
- Proxy option for An Post IP whitelisting purpose
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
    remote_path: '/path/to/remote/files'  # The remote directory where An Post places tracking files
  }

  # Optional proxy configuration (for An Post IP whitelisting)
  config.proxy_config = {
    host: 'proxy-host',
    port: 'proxy-port',
    user: 'proxy-user',     # Optional proxy authentication
    password: 'proxy-password'  # Optional proxy authentication
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
  product_code: "DOM",  # DOM for domestic, EU for European Union, INT for International
  weight: 1.5,  # Weight in kilograms

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
puts label.tracking_number  # The An Post tracking number for this shipment
puts label.label_url       # URL to download the generated label
```

### Tracking Shipments

The tracking system works with An Post's SFTP service, where tracking files are named in the format:
`CDT99999999SSSSS.txt` where:

- CDT is the prefix (Customer Data Tracking)
- 99999999 is your An Post Customer Account Number
- SSSSS is a sequence number (starts at 1, increments by 1 for each file)
- .txt is the file extension

```ruby
tracker = AnPostReturn::Tracker.new

# Track by account number (gets all files)
# This will retrieve all tracking files for the given account number
tracker.track_with_account_number("3795540") do |file, data|
  puts "Processing file: #{file}"
  puts "Tracking data: #{data}"
end

# Track by account number (get last N files)
# Useful when you only want recent tracking updates
tracker.track_with_account_number("3795540", last: 2) do |file, data|
  puts "Processing file: #{file}"
  puts "Tracking data: #{data}"
end

# Track from a specific file onwards, by incrementing file name by 1 until no file is found
# Useful for resuming tracking from a known point
tracker.track_from("cdt0370132115864.txt") do |file, data|
  puts "Processing file: #{file}"
  puts "Tracking data: #{data}"
end
```

The tracking data structure contains:

- `:header` - File header information including account details
- `:data` - Array of tracking events for multiple shipments
- `:footer` - File footer information including totals

Possible tracking statuses:

- "SORTED" - Item has been sorted at An Post facility
- "ATTEMPTED DELIVERY" - Delivery was attempted but not completed
- "DELIVERED" - Item has been successfully delivered
- "ITEM ON HAND" - Item is being held at An Post facility
- "PRE-ADVICE" - Item is expected but not yet received
- "OUT FOR DELIVERY" - Item is on the delivery vehicle
- "ITEM ACCEPTED" - Item has been received by An Post
- "CUSTOMER INSTRUCTION REC" - Customer has provided special instructions

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/PostCo/an_post_return. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/PostCo/an_post_return/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AnPostReturn project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/PostCo/an_post_return/blob/main/CODE_OF_CONDUCT.md).
