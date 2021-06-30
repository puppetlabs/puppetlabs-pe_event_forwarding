#!/opt/puppetlabs/puppet/bin/ruby
require 'find'
require 'yaml'

def require_classes(modulepaths)
  catch :done do
    modulepaths.split(':').each do |modulepath|
      Find.find(modulepath) do |path|
        if %r{common_events_library.gemspec}.match?(path)
          $LOAD_PATH.unshift("#{File.dirname(path)}/lib")
          throw :done
        end
      end
    end
  end

  require 'events_collection/lockfile'
  require 'events_collection/orchestrator_event'
  require 'common_events_library'
end

def main(confdir, modulepaths, statedir)
  require_classes(modulepaths)

  begin
    lockfile = CommonEvents::Lockfile.new(statedir)
    settings = YAML.safe_load(File.read("#{confdir}/events_collection.yaml"))
    if lockfile.already_running?
      puts 'already running'
    else
      lockfile.write_lockfile
      orchestrator_client = Orchestrator.new('localhost', username: settings['pe_username'], password: settings['pe_password'], token: settings['pe_token'], ssl_verify: false)
      puts orchestrator_client.get_jobs(limit: 1)
      # Find any compatible reports
      # Reports should be in /lib/reports/common_events
    end
  rescue => exception
    puts exception
  ensure
    lockfile.remove_lockfile
  end
end

if $PROGRAM_NAME == __FILE__
  confdir     = ARGV[0] || '/etc/puppetlabs/puppet'
  modulepaths = ARGV[1] || '/etc/puppetlabs/code/environments/production/modules:/etc/puppetlabs/code/environments/production/site:/etc/puppetlabs/code/modules:/opt/puppetlabs/puppet/modules'
  statedir    = ARGV[2] || '/etc/puppetlabs/puppet'
  main(confdir, modulepaths, statedir)
end
