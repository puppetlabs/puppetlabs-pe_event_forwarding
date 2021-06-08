#!/opt/puppetlabs/puppet/bin/ruby
require 'find'
require 'yaml'

def require_classes(modulepaths)
  catch :done do
    modulepaths.split(':').each do |modulepath|
      Find.find(modulepath) do |path|
        if path =~ %r{common_events_library.gemspec}
          $LOAD_PATH.unshift("#{File.dirname(path)}/lib")
          throw :done
        end
      end
    end
  end

  require 'events_collection/orchestrator_event'
  require 'common_events_library'
end

def main(confdir, modulepaths)
  require_classes(modulepaths)

  settings = YAML.safe_load(File.read("#{confdir}/events_collection.yaml"))

  orchestrator_client = Orchestrator.new('localhost', username: settings['pe_username'], password: settings['pe_password'], token: settings['pe_token'], ssl_verify: false)
  puts orchestrator_client.get_jobs(limit: 1)
end

if $PROGRAM_NAME == __FILE__
  confdir     = ARGV[0]
  modulepaths = ARGV[1]
  main(confdir, modulepaths)
end
