#!/opt/puppetlabs/puppet/bin/ruby
require 'find'
require 'yaml'

require_relative 'api/activity'
require_relative 'api/orchestrator'
require_relative 'util/lockfile'
require_relative 'util/http'
require_relative 'util/pe_http'
require_relative 'util/index'
require_relative 'util/processor'
require_relative 'util/logger'

confdir     = ARGV[0] || '/etc/puppetlabs/puppet/common_events'
modulepaths = ARGV[1] || '/etc/puppetlabs/code/environments/production/modules:/etc/puppetlabs/code/environments/production/site:/etc/puppetlabs/code/modules:/opt/puppetlabs/puppet/modules'
statedir    = ARGV[2] || '/etc/puppetlabs/puppet/common_events'

def main(confdir, _modulepaths, statedir)
  log      = CommonEvents::Logger.new('/tmp/common_events.log')
  lockfile = CommonEvents::Lockfile.new(statedir)

  if lockfile.already_running?
    log.warn('previous run is not complete')
    exit
  end

  lockfile.write_lockfile
  settings = YAML.safe_load(File.read("#{confdir}/events_collection.yaml"))
  index = CommonEvents::Index.new(statedir)
  data = {}

  client_options = {
    username:    settings['pe_username'],
    password:    settings['pe_password'],
    token:       settings['pe_token'],
    ssl_verify:  false
  }

  orchestrator = CommonEvents::Orchestrator.new('localhost', client_options)
  activities   = CommonEvents::Activity.new('localhost', client_options)

  data[:orchestrator] = orchestrator.new_data(index.count(:orchestrator))

  CommonEvents::Activity::SERVICE_NAMES.each do |service|
    data[service] = activities.new_data(service, index.count(service))
  end

  CommonEvents::Processor.find_each("#{confdir}/processors.d") do |processor|
    processor.invoke(data)
    log.info(processor.stdout, source: processor.name)
    log.warn(processor.stderr, source: processor.name, exit_code: processor.exitcode) unless processor.stderr.length.zero? && processor.exitcode == 0
  end

  index.save(data)
rescue => exception
  puts exception
  puts exception.backtrace
ensure
  lockfile.remove_lockfile
end

if $PROGRAM_NAME == __FILE__
  main(confdir, modulepaths, statedir)
end
