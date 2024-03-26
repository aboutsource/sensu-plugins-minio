# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/sensu/plugins/minio/version'

Gem::Specification.new do |spec|
  spec.name          = 'sensu-plugins-minio'
  spec.version       = Sensu::Plugins::Minio::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ['Hauke Altmann', 'Jonathan Schlue',
                        'Benjamin Meichsner']
  spec.email         = ['info@aboutsource.net']

  spec.summary       = 'Check if there are updates for the local '\
                       'minio server instance'
  spec.description   = 'Used to check for manual installed minio servers'
  spec.homepage      = 'https://github.com/aboutsource/sensu-plugins-minio'
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3.3'

  spec.executables = Dir.glob('bin/**/*.rb').map { |f| File.basename(f) }
  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.add_dependency 'sensu-plugin', '~> 2.1'
  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.10'
  spec.add_development_dependency 'rubocop', '~> 0.54', '<= 0.81'
  spec.add_development_dependency 'webmock', '~> 3.3'
end
