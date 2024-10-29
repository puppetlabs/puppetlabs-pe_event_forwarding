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

  timeout = settings['timeout'] || 60

  orchestrator = PeEventForwarding::Orchestrator.new(settings['pe_console'], **client_options)
  activities = PeEventForwarding::Activity.new(settings['pe_console'], **client_options)

  service_names = if !settings['skip_events'].nil?
                    PeEventForwarding::Activity::SERVICE_NAMES.reject do |service|
                      settings['skip_events'].include?(service.to_s)
                    end
                  else
                    PeEventForwarding::Activity::SERVICE_NAMES
                  end

  if index.first_run?
    if settings['skip_jobs'].nil?
      data[:orchestrator] = orchestrator.current_job_count(timeout)
    end
    service_names.each do |service|
      log.debug("Starting #{service} for first run with #{index.count(service)} event(s)")
      data[service] = activities.current_event_count(service, timeout)
    end
    index.save(**data)
    log.debug("First run. Recorded event count in #{index.filepath} and now exiting.")
    exit
  end

  # We mark the index with -1 for any event types that are skipped to signify that
  # they have been disabled. This is neccesary because upon re-enablement we want to
  # make sure we only re-initialize the index for the re-enabled services. This ensures
  # the other services continue as normal, and we don't pull in a large amount of events
  # that have accumulated in the interim.
  settings['skip_events']&.each do |service|
    data[service.to_sym] = -1
  end

  if settings['skip_jobs']
    data[:orchestrator] = -1
  elsif settings['skip_jobs'].nil? && index.count(:orchestrator) == -1
    # At this point we know orchestrator is newly re-enabled.
    # Reinitialize the orchestrator event count and exit.
    # Next run will continue as usual.
    data[:orchestrator] = orchestrator.current_job_count(timeout)
    index.save(**data)
    log.debug("Orchestration jobs collection reenabled. First run. Recorded event count in #{index.filepath}.")
    # The index is now saved, so to ensure that the count does not get passed to any
    # processors (which should be written to check for `nil` or `-1`) we set it to nil.
    data[:orchestrator] = nil
  else
    log.debug("Orchestrator: Starting count: #{index.count(:orchestrator)}")
    data[:orchestrator] = orchestrator.new_data(index.count(:orchestrator), timeout)
  end

  service_names.each do |service|
    if index.count(service) == -1
      # At this point we know the service is newly re-enabled.
      # Reinitialize the event count and exit.
      # Next run will continue as usual.
      data[service] = activities.current_event_count(service, timeout)
      index.save(**data)
      log.debug("Collection of #{service} events reenabled. First run. Recorded event count in #{index.filepath}.")
      # The index is now saved, so to ensure that the count does not get passed to any
      # processors (which should be written to check for `nil` or `-1`) we set it to nil.
      data[service] = nil
    else
      log.debug("#{service}: Starting count #{index.count(service)} event(s)")
      data[service] = activities.new_data(service, index.count(service), settings['api_page_size'], timeout)
    end
  end

  combined_keys = if settings['skip_jobs'].nil?
                    service_names.dup << :orchestrator
                  else
                    service_names.dup
                  end
  events_counts = {}
  combined_keys.map do |key|
    events_counts[key] = data[key].count unless data[key].nil? || data[key].is_a?(Integer)
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
