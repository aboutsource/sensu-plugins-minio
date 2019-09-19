# Sensu check for minio updates

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sensu-plugins-minio'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sensu-plugins-minio

## USAGE
Check if a the local minio version is in the most recent version

### Optional parameters

Checks will check the default URL https://dl.min.io/server/minio/release 
and the default Platform linux-amd64 for updates. Adjust these optional 
parameters if you want to check a different platform or for whatever 
reason need to check a differen URL.

| Parameter          | Description                                     |
| ------------------ | ----------------------------------------------- |
| -u URL             | Url of minio site containing update information |
| -p PLATFORM        | OS Platform to check for                        |
| --timeout TIMEOUT  | Update website request timeout in seconds       |

### Example:
```
 ./bin/check-minio-update.rb
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can
also run `bin/console` for an interactive prompt that will allow you to
experiment.

To run the tests execute `bundle exec rspec spec`.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

Plugin follows the [rubocop ruby style guide](https://github.com/rubocop-hq/ruby-style-guide)

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/aboutsource/sensu-plugins-minio.
