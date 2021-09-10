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

confdir   = ARGV[0] || '/etc/puppetlabs/pe_event_forwarding'
logpath   = ARGV[1] || '/var/log/puppetlabs/pe_event_forwarding/pe_event_forwarding.log'
lockdir   = ARGV[2] || '/opt/puppetlabs/pe_event_forwarding/cache/state'

def main(confdir, logpath, lockdir)
  common_event_start_time = Time.now
  settings = YAML.safe_load(File.read("#{confdir}/events_collection.yaml"))
  log = PeEventForwarding::Logger.new(logpath, settings['log_rotation'])
  log.level = PeEventForwarding::Logger::LOG_LEVELS[settings['log_level']]
  lockfile = PeEventForwarding::Lockfile.new(lockdir)

  if lockfile.already_running?
    log.warn('previous run is not complete')
    exit
  end

  lockfile.write_lockfile
  if lockfile.lockfile_exists?
    log.debug('Lockfile was successfully created.')
  else
    log.error('Lockfile creation failed.')
  end
  index = PeEventForwarding::Index.new(confdir)
  data = {}

  client_options = {
    username:    settings['pe_username'],
    password:    settings['pe_password'],
    token:       settings['pe_token'],
    ssl_verify:  false
  }

  orchestrator = PeEventForwarding::Orchestrator.new(settings['pe_console'], client_options)
  activities = PeEventForwarding::Activity.new(settings['pe_console'], client_options)

  if index.first_run?
    data[:orchestrator] = orchestrator.current_job_count
    PeEventForwarding::Activity::SERVICE_NAMES.each do |service|
      log.debug("Starting #{service} for first run with #{index.count(service)} event(s)")
      data[service] = activities.current_event_count(service)
    end
    index.save(data)
    log.debug("First run. Recorded event count in #{index.filepath} and now exiting.")
    exit
  end

  data[:orchestrator] = orchestrator.new_data(index.count(:orchestrator), settings['api_window_size'])

  PeEventForwarding::Activity::SERVICE_NAMES.each do |service|
    data[service] = activities.new_data(service, index.count(service), settings['api_window_size'])
    log.debug("Starting #{service} with #{index.count(service)} event(s)")
  end

  if data.any? { |_k, v| !v.nil? }
    PeEventForwarding::Processor.find_each("#{confdir}/processors.d") do |processor|
      start_time = Time.now
      processor.invoke(data)
      duration = Time.now - start_time
      log.debug(processor.stdout, source: processor.name)
      log.warn(processor.stderr, source: processor.name, exit_code: processor.exitcode) unless processor.stderr.length.zero? && processor.exitcode == 0
      log.debug("Invoked #{processor.name} took #{duration} second(s) to complete.")
    end
    index.save(data)
    log.debug("Total execution time is: #{Time.now - common_event_start_time} second(s)")
  end
rescue => exception
  puts exception
  puts exception.backtrace
  log.error("Caught an exception #{exception}")
ensure
  lockfile.remove_lockfile
end

if $PROGRAM_NAME == __FILE__
  main(confdir, logpath, lockdir)
end
