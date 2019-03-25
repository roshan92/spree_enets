# SpreeEnets

eNETS gateway for SpreeCommerce

## Installation

1. Add this extension to your Gemfile with this line:

```ruby
gem 'spree_enets', github: 'roshan92/spree_enets'
```

2. Install the gem using Bundler:
```ruby
bundle install
```

3. Copy & run migrations
```ruby
bundle exec rails g spree_enets:install
```

4. Restart your server

## Setup

1. Go to admin panel and create a new payment method using `Spree::Gateway::Enets` provider
2. Puts your API credentials, and set mode `prod` or `sandbox`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/roshan92/spree_enets. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
