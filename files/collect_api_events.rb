#!/opt/puppetlabs/puppet/bin/ruby
require 'find'
require 'yaml'

require_relative 'api/events'
require_relative 'api/orchestrator'
require_relative 'util/lockfile'
require_relative 'util/http'
require_relative 'util/pe_http'
require_relative 'util/index'
require_relative 'util/processor'
require_relative 'util/logger'

def main(confdir, _modulepaths, statedir)
  log = CommonEvents::Logger.new('/tmp/common_events.log')
  lockfile = CommonEvents::Lockfile.new(statedir)
  settings = YAML.safe_load(File.read("#{confdir}/events_collection.yaml"))
  if lockfile.already_running?
    puts 'already running'
  else
    lockfile.write_lockfile
    index = CommonEvents::Index.new(statedir)
    data = {}

    orchestrator_client = CommonEvents::Orchestrator.new('localhost', username: settings['pe_username'], password: settings['pe_password'], token: settings['pe_token'], ssl_verify: false)
    current_count       = orchestrator_client.current_job_count
    # puts "current_count: #{puts current_count}"
    new_count           = index.new_items(:orchestrator, current_count)
    # puts "new_count: #{new_count}"
    if new_count > 0
      data[:orchestrator] = orchestrator_client.get_jobs(limit: new_count, offset: index.count(:orchestrator), order: 'asc', order_by: 'name')
      index.save(orchestrator: current_count)
    end
    services = [:classifier, :rbac, :'pe-console', :'code-manager' ]

    events_client = CommonEvents::Events.new('localhost', username: settings['pe_username'], password: settings['pe_password'], token: settings['pe_token'], ssl_verify: false)
    services.each do |service|
      current_count = events_client.current_event_count(service)
      last_count = index.count(service)
      new_count = index.new_items(service, current_count)
      next unless new_count > 0
      data[service] = events_client.get_events(service: service, offset: last_count, limit: new_count)
      index.save(service => current_count)
    end

    CommonEvents::Processor.find_each("#{confdir}/processors.d") do |processor|
      processor.invoke(data)
      log.info(processor.stdout, source: processor.name)
      log.warn(processor.stderr, source: processor.name) unless processor.stderr.length.zero?
    end
  end
rescue => exception
  puts exception
  puts exception.backtrace
ensure
  lockfile.remove_lockfile
end

if $PROGRAM_NAME == __FILE__
  confdir     = ARGV[0] || '/etc/puppetlabs/puppet/common_events'
  modulepaths = ARGV[1] || '/etc/puppetlabs/code/environments/production/modules:/etc/puppetlabs/code/environments/production/site:/etc/puppetlabs/code/modules:/opt/puppetlabs/puppet/modules'
  statedir    = ARGV[2] || '/etc/puppetlabs/puppet/common_events'
  main(confdir, modulepaths, statedir)
end
