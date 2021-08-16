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

confdir   = ARGV[0] || '/etc/puppetlabs/puppet/common_events'
logpath   = ARGV[1] || '/var/log/puppetlabs/common_events/common_events.log'
lockdir   = ARGV[2] || '/opt/puppetlabs/common_events/cache/state'

def main(confdir, logpath, lockdir)
  settings = YAML.safe_load(File.read("#{confdir}/events_collection.yaml"))
  log = CommonEvents::Logger.new(logpath, settings['log_rotation'])
  lockfile = CommonEvents::Lockfile.new(lockdir)

  if lockfile.already_running?
    log.warn('previous run is not complete')
    exit
  end

  lockfile.write_lockfile
  log.level = CommonEvents::Logger::LOG_LEVELS[settings['log_level']]
  index = CommonEvents::Index.new(confdir)
  data = {}

  client_options = {
    username:    settings['pe_username'],
    password:    settings['pe_password'],
    token:       settings['pe_token'],
    ssl_verify:  false
  }

  orchestrator = CommonEvents::Orchestrator.new('localhost', client_options)
  activities = CommonEvents::Activity.new('localhost', client_options)

  if index.first_run?
    data[:orchestrator] = orchestrator.current_job_count
    CommonEvents::Activity::SERVICE_NAMES.each do |service|
      data[service] = activities.current_event_count(service)
    end
    index.save(data)
    log.warn('First run. Recorded event count and now exiting.')
    exit
  end

  data[:orchestrator] = orchestrator.new_data(index.count(:orchestrator))

  CommonEvents::Activity::SERVICE_NAMES.each do |service|
    data[service] = activities.new_data(service, index.count(service))
  end

  if data.any? { |_k, v| !v.nil? }
    CommonEvents::Processor.find_each("#{confdir}/processors.d") do |processor|
      processor.invoke(data)
      log.info(processor.stdout, source: processor.name)
      log.warn(processor.stderr, source: processor.name, exit_code: processor.exitcode) unless processor.stderr.length.zero? && processor.exitcode == 0
    end
    index.save(data)
  end
rescue => exception
  puts exception
  puts exception.backtrace
ensure
  lockfile.remove_lockfile
end

if $PROGRAM_NAME == __FILE__
  main(confdir, logpath, lockdir)
end
