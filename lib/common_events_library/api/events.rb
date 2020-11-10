require_relative '../util/pe_http'

# module Events This contains the API specific code for the events API
module Events
  def get_all_events(pe_console, username, password, service = 'classifier', offset = 0, limit = 0, ssl_verify: true)
    http = PeHttp.new(pe_console, port: 4433, username: username, password: password, ssl_verify: ssl_verify)
    uri = PeHttp.make_params("activity-api/v1/events?service_id=#{service}", limit, offset)
    http.pe_get_request(uri)
  end
  module_function :get_all_events
end
