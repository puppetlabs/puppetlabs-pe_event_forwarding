require_relative '../lib/common_events_library/api/orchestrator'
require 'benchmark'

PE_CONSOLE = ENV['PT_PE_CONSOLE']
USERNAME = ENV['PT_PE_USERNAME'] || 'admin'
PASSWORD = ENV['PT_PE_PASSWORD'] || 'pie'

raise 'usage: PT_PE_CONSOLE=<fqdn> events.rb' if PE_CONSOLE.nil?

token = Http.get_token(PE_CONSOLE, USERNAME, PASSWORD)

response = Orchestrator.get_all_jobs(token, PE_CONSOLE)

puts response.body
