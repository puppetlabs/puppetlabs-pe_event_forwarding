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
  settings = YAML.safe_load(File.read("#{confdir}/collection_settings.yaml"))
  secrets = YAML.safe_load(File.read("#{confdir}/collection_secrets.yaml"))
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
    username:    secrets['pe_username'],
    password:    secrets['pe_password'],
    token:       secrets['pe_token'],
    ssl_verify:  false,
    log: log
  }

  orchestrator = PeEventForwarding::Orchestrator.new(settings['pe_console'], **client_options)
  activities = PeEventForwarding::Activity.new(settings['pe_console'], **client_options)

  service_names = (settings['disable_rbac'] == 'false') ? PeEventForwarding::Activity::SERVICE_NAMES_WITH_RBAC : PeEventForwarding::Activity::SERVICE_NAMES_WITHOUT_RBAC

  if index.first_run?
    data[:orchestrator] = orchestrator.current_job_count
    service_names.each do |service|
      log.debug("Starting #{service} for first run with #{index.count(service)} event(s)")
      data[service] = activities.current_event_count(service)
    end
    index.save(**data)
    log.debug("First run. Recorded event count in #{index.filepath} and now exiting.")
    exit
  end

  log.debug("Orchestrator: Starting count: #{index.count(:orchestrator)}")
  data[:orchestrator] = orchestrator.new_data(index.count(:orchestrator), settings['api_page_size'])

  # We mark the rbac index with -1 to signify that it has been disabled.
  # This is neccesary because upon re-enablement we want to make sure we
  # only re-initialize the rbac index so the others continue as normal, and
  # we don't pull in a large amount of rbac events that have accumulated in the
  # interim.
  data[:rbac] = -1 if settings['disable_rbac'] == 'true'

  service_names.each do |service|
    if (service == :rbac) && (index.count(service) == -1)
      # At this point we know rbac is newly re-enabled.
      # Reinitialize the rbac event count and exit.
      # Next run will continue as usual.
      data[service] = activities.current_event_count(service)
      index.save(**data)
      log.debug("RBAC events collection reenabled. First run. Recorded event count in #{index.filepath} and now exiting.")
      exit
    else
      log.debug("#{service}: Starting count #{index.count(service)} event(s)")
      data[service] = activities.new_data(service, index.count(service), settings['api_page_size'])
    end
  end

  combined_keys = service_names.dup << :orchestrator
  events_counts = {}
  combined_keys.map do |key|
    events_counts[key] = data[key].count unless data[key].nil?
  end

  if data.any? { |_k, v| !v.nil? || (v != -1) }
    PeEventForwarding::Processor.find_each("#{confdir}/processors.d") do |processor|
      log.info("#{processor.name} starting with events: #{events_counts}")
      start_time = Time.now
      processor.invoke(data)
      duration = Time.now - start_time
      log.info(processor.stdout, source: processor.name) unless processor.stdout.empty?
      log.warn(processor.stderr, source: processor.name, exit_code: processor.exitcode) unless processor.stderr.empty? && processor.exitcode == 0
      log.info("#{processor.name} finished: #{duration} second(s) to complete.")
    end
    index.save(**data)
  end
  log.info("Event Forwarding total execution time: #{Time.now - common_event_start_time} second(s)")
rescue => exception
  puts exception
  puts exception.backtrace
  log.error("Caught an exception #{exception}: #{exception.backtrace}")
ensure
  lockfile.remove_lockfile
end

if $PROGRAM_NAME == __FILE__
  main(confdir, logpath, lockdir)
end
