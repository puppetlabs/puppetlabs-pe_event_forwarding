lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'common_events_library/version'

Gem::Specification.new do |spec|
  spec.name = 'common_events_library'
  spec.version     = CommonEventsLibrary::VERSION
  spec.homepage    = 'https://github.com/puppetlabs/common_events_library'
  spec.license     = 'Apache-2.0'
  spec.authors     = ['Puppet, Inc.']
  spec.email       = ['info@puppet.com']
  spec.files       = Dir[
    'README.md',
    'LICENSE',
    'lib/**/*',
    'spec/**/*',
  ]
  spec.test_files  = Dir['spec/**/*']
  spec.description = <<-EOF
    Providing a simple library that enables users to collect and process Puppet PE audits, events and orchetrator APIs.
  EOF
  spec.summary = 'Providing support for PE report processing and Orchestrator/Event APIs.'
  spec.add_runtime_dependency 'rspec'
end
