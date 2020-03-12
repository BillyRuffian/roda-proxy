# frozen_string_literal: true

require_relative 'lib/roda/proxy/version'

Gem::Specification.new do |spec|
  spec.name          = 'roda-proxy'
  spec.version       = Roda::Proxy::VERSION
  spec.authors       = ['Nigel Brookes-Thomas']
  spec.email         = ['nigel@brookes-thomas.co.uk']

  spec.summary       = 'Proxy service for Roda'
  spec.description   = 'Roda proxy service'
  spec.homepage      = 'http://foo.bar'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'http://foo.bar'
  spec.metadata['changelog_uri'] = 'http://foo.bar'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  
  spec.add_dependency 'faraday', '~> 1.0'
  spec.add_dependency 'roda', '~> 3.0'
  
  spec.add_development_dependency 'rerun', '~> 0.13'
  spec.add_development_dependency 'rubocop', '~> 0.80'
end
