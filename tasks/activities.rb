require_relative '../lib/common_events_library/api/activity.rb'

PE_CONSOLE = ENV['PT_pe_console']
USERNAME = ENV['PT_pe_username'] || 'admin'
PASSWORD = ENV['PT_pe_password'] || 'pie'

raise 'usage: PT_PE_CONSOLE=<fqdn> events.rb' if PE_CONSOLE.nil?

events_client = CommonEvents::Activity.new(PE_CONSOLE, USERNAME, PASSWORD, ssl_verify: false)
response = events_client.get_all_events

puts JSON.pretty_generate(JSON.parse(response.body))
