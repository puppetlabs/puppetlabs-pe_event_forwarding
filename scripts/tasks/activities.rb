require_relative '../lib/common_events_library/api/activity'

PE_CONSOLE = ENV['PT_PE_CONSOLE']
USERNAME = ENV['PT_PE_USERNAME'] || 'admin'
PASSWORD = ENV['PT_PE_PASSWORD'] || 'pie'

raise 'usage: PT_PE_CONSOLE=<fqdn> events.rb' if PE_CONSOLE.nil?

token = CommonEvents::Http.get_pe_token(PE_CONSOLE, USERNAME, PASSWORD, ssl_verify: false)

response = CommonEvents::Activity.get_all_events(token, PE_CONSOLE, ssl_verify: false)

puts JSON.pretty_generate(JSON.parse(response.body))
