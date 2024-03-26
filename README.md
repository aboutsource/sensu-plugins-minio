# Sensu check for minio updates

Translates the presence of an outdated minio server instance into sensu check
results to reduce the time-to-patch for minio systems.

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
reason need to check a different URL.

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

Install rbenv and ruby-build to get a ruby 2.7.x on your system (running on ubuntu 20.04).

    yay -S rbenv ruby-build

Add the rbenv shell extension (`eval "$(rbenv init -)"`) to your shell config (e.g. `~/.zshrc`) and install ruby 2.7.0

    rbenv install 2.7.0

After checking out the repo verify, that your system is using the 2.7.0 ruby:

    # rbenv version
    2.7.0 (set by ..../sensu-plugins-minio/.ruby-version)

Run `bin/setup` to install dependencies. You can
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

## Security

* [Snyk](https://app.snyk.io/org/about-source/project/0a24cb05-4369-457c-8cca-7e4c395eb25e)
