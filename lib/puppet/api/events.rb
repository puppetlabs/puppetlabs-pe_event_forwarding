require_relative '../util/http'

# module Events This contains the API specific code for the events API
module Events
  def get_all_events(token, pe_console, service = 'classifier', offset = 0, limit = 0)
    auth_header = { 'X-Authentication' => token.to_s }
    uri = "activity-api/v1/events?service_id=#{service}"
    uri = "#{uri}&offset=#{offset}" unless offset.zero?
    uri = "#{uri}&limit=#{limit}" unless limit.zero?
    Http.get_request(pe_console, 4433, uri, auth_header)
  end
  module_function :get_all_events
end
