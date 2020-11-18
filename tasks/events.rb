require_relative '../lib/common_events_library/api/events.rb'

PE_CONSOLE = ENV['PT_pe_console']
USERNAME = ENV['PT_pe_username'] || 'admin'
PASSWORD = ENV['PT_pe_password'] || 'pie'

raise 'usage: PT_PE_CONSOLE=<fqdn> events.rb' if PE_CONSOLE.nil?

response = Events.get_all_events(PE_CONSOLE, USERNAME, PASSWORD, ssl_verify: false)

puts JSON.pretty_generate(JSON.parse(response.body))
