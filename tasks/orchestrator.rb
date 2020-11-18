require_relative '../lib/common_events_library/api/orchestrator.rb'
require 'benchmark'

PE_CONSOLE = ENV['PT_pe_console']
USERNAME = ENV['PT_pe_username'] || 'admin'
PASSWORD = ENV['PT_pe_password'] || 'pie'

raise 'usage: PT_PE_CONSOLE=<fqdn> events.rb' if PE_CONSOLE.nil?

response = Orchestrator.get_all_jobs(PE_CONSOLE, USERNAME, PASSWORD, ssl_verify: false)

puts response.body
