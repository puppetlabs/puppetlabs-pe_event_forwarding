#!/opt/puppetlabs/puppet/bin/ruby
require 'find'
require 'yaml'

require_relative 'api/events'
require_relative 'api/orchestrator'
require_relative 'util/lockfile'
require_relative 'util/http'
require_relative 'util/pe_http'
require_relative 'util/index'

def main(confdir, _modulepaths, statedir)
  lockfile = CommonEvents::Lockfile.new(statedir)
  settings = YAML.safe_load(File.read("#{confdir}/events_collection.yaml"))
  if lockfile.already_running?
    puts 'already running'
  else
    lockfile.write_lockfile
    orchestrator_client = CommonEvents::Orchestrator.new('localhost', username: settings['pe_username'], password: settings['pe_password'], token: settings['pe_token'], ssl_verify: false)
    orchestrator_index = CommonEvents::Index.new(statedir, 'orchestrator')
    current_count = orchestrator_client.current_job_count

    puts orchestrator_index.count
    puts current_count
    new_count = orchestrator_index.new_items(current_count)
    puts new_count
    orchestrator_index.save_latest_index(current_count)

    events_index = CommonEvents::Index.new(statedir, 'events')
    puts "events count: #{events_index.count}"
    events_index.save_latest_index(15)
    puts "events count 2: #{events_index.count}"

    puts File.read(events_index.filepath)

    # Find any compatible reports
    # Reports should be in /lib/reports/common_events
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
