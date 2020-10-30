require_relative '../lib/common_events_library/api/events'

PE_CONSOLE = ENV['PT_PE_CONSOLE']
USERNAME = ENV['PT_PE_USERNAME'] || 'admin'
PASSWORD = ENV['PT_PE_PASSWORD'] || 'pie'

raise 'usage: PT_PE_CONSOLE=<fqdn> events.rb' if PE_CONSOLE.nil?

token = Http.get_token(PE_CONSOLE, USERNAME, PASSWORD)

response = Events.get_all_events(token, PE_CONSOLE)

puts JSON.pretty_generate(JSON.parse(response.body))
