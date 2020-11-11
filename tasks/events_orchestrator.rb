require_relative '../lib/common-events_library/api/orchestrator'
require_relative '../lib/common-events_library/api/events'

require 'benchmark'

PE_CONSOLE = ENV['PT_PE_CONSOLE']
USERNAME = ENV['PT_PE_USERNAME'] || 'admin'
PASSWORD = ENV['PT_PE_PASSWORD'] || 'pie'

raise 'usage: PT_PE_CONSOLE=<fqdn> events.rb' if PE_CONSOLE.nil?

token = Http.get_pe_token(PE_CONSOLE, USERNAME, PASSWORD, ssl_verify: false)
response = ''

all_events_time = Benchmark.realtime do
  response = Events.get_all_events(token, PE_CONSOLE, ssl_verify: false)
end

count = 0
time = Benchmark.realtime do
  puts 'Jobs => extracting details'
  events = JSON.parse(response.body)

  events['commits'].each do |parent_event|
    parent_event['events'].each do |event|
      next unless event['message'].include? 'Request task run'
      job_id = event['message'].split.last.gsub!(%r{^\"|\"?$}, '')
      printf "\tGetting job %s ", job_id
      response = Orchestrator.get_job(token, PE_CONSOLE, job_id, 2, 2)
      job = JSON.parse(response.body)
      printf "type=%s state=%s %s\n", job['type'], job['state'], job['timestamp']

      count += 1
    end
  end
end

puts "all events time taken =#{all_events_time} seconds"
puts "job total=#{count} time taken=#{time} @ #{time / count} jobs/s"
