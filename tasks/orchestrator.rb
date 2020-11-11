require_relative '../lib/common-events_library/api/orchestrator'
require 'benchmark'

PE_CONSOLE = ENV['PT_PE_CONSOLE']
USERNAME = ENV['PT_PE_USERNAME'] || 'admin'
PASSWORD = ENV['PT_PE_PASSWORD'] || 'pie'

raise 'usage: PT_PE_CONSOLE=<fqdn> events.rb' if PE_CONSOLE.nil?

token = Http.get_pe_token(PE_CONSOLE, USERNAME, PASSWORD, ssl_verify: false)

response = Orchestrator.get_all_jobs(token, PE_CONSOLE, ssl_verify: false)

puts response.body
