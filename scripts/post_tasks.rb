require_relative '../lib/common_events_library/api/orchestrator'

require 'benchmark'

PE_CONSOLE = ENV['PT_PE_CONSOLE']
USERNAME = ENV['PT_PE_USERNAME'] || 'admin'
PASSWORD = ENV['PT_PE_PASSWORD'] || 'pie'

raise 'usage: PT_PE_CONSOLE=<fqdn> events.rb' if PE_CONSOLE.nil?

orchestrator = Orchestrator.new(PE_CONSOLE, USERNAME, PASSWORD, ssl_verify: false)

batch = 1..10
batch.each do
  response = ''

  r = 1..2
  puts 'Sending batch tasks to PE'
  time = Benchmark.realtime do
    r.each do |x|
      puts "Injecting task [#{x}]"
      response = orchestrator.run_facts_task([PE_CONSOLE])
    end
  end

  # wait for the last of the batch to complete
  id = Orchestrator.get_id_from_response(response)
  Orchestrator.wait_until_finished(token, PE_CONSOLE, id)
  puts "batch time taken=#{time} seconds"
end
