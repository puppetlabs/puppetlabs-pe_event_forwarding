require_relative '../lib/common-events_library/api/orchestrator'
require 'benchmark'

PE_CONSOLE = ENV['PT_PE_CONSOLE']
USERNAME = ENV['PT_PE_USERNAME'] || 'admin'
PASSWORD = ENV['PT_PE_PASSWORD'] || 'pie'

raise 'usage: PT_PE_CONSOLE=<fqdn> events.rb' if PE_CONSOLE.nil?

token = Http.get_pe_token(PE_CONSOLE, USERNAME, PASSWORD, ssl_verify: false)
response = ''

all_jobs_time = Benchmark.realtime do
  response = Orchestrator.get_all_jobs(token, PE_CONSOLE)
end

count = 0
time = Benchmark.realtime do
  puts 'Jobs => extracting details'
  tasks = JSON.parse(response.body)
  tasks['items'].each do |task|
    printf "\tGetting job %s ", task['name']
    response = Orchestrator.get_job(token, PE_CONSOLE, task['name'], 2, 2)
    job = JSON.parse(response.body)
    printf "type=%s state=%s %s\n", job['type'], job['state'], job['timestamp']
    count += 1
  end
end
puts "all jobs time taken=#{all_jobs_time} seconds"
puts "job total=#{count} time taken=#{time} @ #{time / count} jobs/s"
