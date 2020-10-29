require_relative '../lib/puppet/api/orchestrator'

require 'benchmark'

PE_CONSOLE = ENV['PT_PE_CONSOLE']
USERNAME = ENV['PT_PE_USERNAME'] || 'admin'
PASSWORD = ENV['PT_PE_PASSWORD'] || 'pie'

raise 'usage: PT_PE_CONSOLE=<fqdn> events.rb' if PE_CONSOLE.nil?

token = Http.get_token(PE_CONSOLE, USERNAME, PASSWORD)
batch = 1..100
batch.each do
  response = ''

  r = 1..20
  puts 'Sending batch tasks to PE'
  time = Benchmark.realtime do
    r.each do |x|
      puts "Injecting task [#{x}]"
      response = Orchestrator.run_facts_task(token, PE_CONSOLE, [PE_CONSOLE])
    end
  end

  # wait for the last of the batch to complete
  id = Orchestrator.get_id_from_response(response)
  Orchestrator.wait_until_finished(token, PE_CONSOLE, id)
  puts "batch time taken=#{time} seconds"
end
